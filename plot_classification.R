library(tidyverse)

df <- read_csv("clean_data/UMRS_FPF_clean.csv")

df

plot_density <- df %>%
  group_by(PID, TR_SP) %>%
  summarize(Count = n()) %>%
  group_by(PID) %>%
  mutate(Density = Count / sum(Count)) %>%
  select(-Count) %>%
  #spread(TR_SP, Density) %>%
  replace(is.na(.), 0)

plot_BasalArea <- df %>%
  group_by(PID, TR_SP) %>%
  summarize(BasalArea = sum(BasalArea)) %>%
  group_by(PID) %>%
  mutate(PctBasalArea = BasalArea / sum(BasalArea)) %>%
  select(-BasalArea) %>%
  #spread(TR_SP, PctBasalArea) %>%
  replace(is.na(.), 0)

plots <- inner_join(plot_density, plot_BasalArea, by = c("PID", "TR_SP"))#, suffix = c("", "_ba"))
#plots$Label <- "Mixed"

dominant <- plots %>%
  filter(Density > 0.8 & PctBasalArea > 0.8)

dominant$Type <- dominant$TR_SP
dominant$Label <- "Dominant"

codominant <- plots %>%
  filter(Density <= 0.8 | PctBasalArea <= 0.8) %>%
  filter(Density >= 0.2 | PctBasalArea >= 0.2) %>%
  group_by(PID) %>%
  filter(Density + max(Density) > 0.8 & PctBasalArea + max(PctBasalArea) > 0.8) %>%
  filter(n() > 1) %>%
  filter(sum(Density) > 0.8 & sum(PctBasalArea) > 0.8)

#Proof that the codominant group is correct - should result in empty data frame
codominant %>% group_by(PID) %>% summarize(d = sum(Density), ba = sum(PctBasalArea)) %>% filter(d <= 0.8 | ba <= 0.8)
#Should also result in empty df if codominant is performed correctly
codominant %>% group_by(PID) %>% summarize(l = length(PID)) %>% filter(l != 2)

codominant <- codominant %>%
  group_by(PID) %>%
  summarize(Density = sum(Density), PctBasalArea = sum(PctBasalArea), Type = paste0(TR_SP, collapse= " and "), Label = "Codominant")

  
  
