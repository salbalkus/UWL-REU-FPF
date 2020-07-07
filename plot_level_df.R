##### imports ######

library(tidyverse)

df <- read_csv("clean_data/UMRS_FPF_clean.csv")
labels <- read_csv("clean_data/plot_classification.csv")
df_cols <- left_join(df, labels, by = "PID") %>% select(PID, TR_SP, TR_DIA, BasalArea, TreesPerAcre, Label)
mixed <- df_cols %>% filter(Label == 'Mixed')
load('cluster_h_d2.RData')
source('Species_dictionary.R')



###### making plot level df #####
plot_freq <- df %>%
  group_by(PID, TR_SP) %>%
  summarize(Freq = n()) %>%
  spread(TR_SP, Freq) %>%
  replace(is.na(.), 0)

plot_BA <- df %>%
  group_by(PID, TR_SP) %>%
  summarize(BA = sum(BasalArea)) %>%
  spread(TR_SP, BA) %>%
  replace(is.na(.), 0)

plot_rel_BA<- df %>%
  group_by(PID, TR_SP) %>%
  summarize(BA = sum(BasalArea)) %>%
  group_by(PID) %>%
  mutate(rel_BA = BA / sum(BA)) %>%
  select(-BA) %>%
  spread(TR_SP, rel_BA) %>%
  replace(is.na(.), 0)

plot_TPA <- df %>%
  group_by(PID, TR_SP) %>%
  summarize(TPA = sum(TreesPerAcre)) %>%
  spread(TR_SP, TPA) %>%
  replace(is.na(.), 0)

plot_rel_TPA <- df %>%
  group_by(PID, TR_SP) %>%
  summarize(TPA = sum(TreesPerAcre)) %>%
  group_by(PID) %>%
  mutate(rel_TPA = TPA / sum(TPA)) %>%
  select(-TPA) %>%
  spread(TR_SP, rel_TPA) %>%
  replace(is.na(.), 0)

plots <- inner_join(plot_BA, plot_rel_BA, by = c("PID"), suffix = c("_BA","_rel_BA"))
plots <- inner_join(plot_freq, plots, by = c("PID"))

plots_tpa <- inner_join(plot_TPA, plot_rel_TPA, by = c("PID"), suffix = c("_TPA","_rel_TPA"))
plots <- inner_join(plots_tpa, plots, by = c("PID"))