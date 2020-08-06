#The purpose of this script is to take the developed classification system and produce some basic summary statistics
#at the plot level and at the class level. It is one of the final scripts in our analysis.

library(tidyverse)

path_of_code <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(path_of_code)

#Load the following:
# Forest labels for each plot
# Level 2 class names for each class
# Original cleaned data file

labels <- read_csv("clean_data/classified_plots_labels_with_mixed.csv")
names <- read_csv("clean_data/names.csv")
data <- read_csv("clean_data/UMRS_FPF_clean.csv")

#Create a data frame including TPA and BA for total, SNAG, and the other health classes, as well as unique species
plots <- data %>% group_by(PID) %>% 
  summarize(Samples = n(),
            TPA = sum(TreesPerAcre),
            BA = sum(BasalArea),
            Unique_Species = n_distinct(TR_SP),
            rel_SNAG_TPA = sum(TreesPerAcre[TR_SP == "SNAG"]) / TPA,
            rel_SNAG_BA = sum(TreesPerAcre[TR_SP == "SNAG"]) / BA,
            rel_V_TPA = sum(TreesPerAcre[TR_HLTH == "V"]) / TPA,
            rel_V_BA = sum(BasalArea[TR_HLTH == "V"]) / BA,
            rel_S_TPA = sum(TreesPerAcre[TR_HLTH == "S"]) / TPA,
            rel_S_BA = sum(BasalArea[TR_HLTH == "S"]) / BA,
            rel_SD_TPA = sum(TreesPerAcre[TR_HLTH == "SD"]) / TPA,
            rel_SD_BA = sum(BasalArea[TR_HLTH == "SD"]) / BA
            )

#Label the data frame with the forest classification system
label_names <- left_join(labels, names, by = c("Type" = "Level1", "cluster" = "cluster"))
plots <- left_join(plots, label_names, by = "PID")

#Write plot-level stats to csv
write_csv(plots,"clean_data/FINAL_plots_summary.csv")

#The following does the same thing, but at the forest type level instead of plot

types <- plots %>% group_by(Label, Type, Name) %>% 
  summarize(Count = n(),
            Pct_Plots = Count / nrow(plots),
            avg_BA = mean(BA),
            avg_TPA = mean(TPA),
            avg_Unique_Species = mean(Unique_Species),
            avg_SNAG_TPA = mean(rel_SNAG_TPA),
            avg_SNAG_BA = mean(rel_SNAG_BA),
            avg_V_TPA = mean(rel_V_TPA),
            avg_V_BA = mean(rel_V_BA),
            avg_S_TPA = mean(rel_S_TPA),
            avg_S_BA = mean(rel_S_BA),
            avg_SD_TPA = mean(rel_SD_TPA),
            avg_SD_BA = mean(rel_SD_BA))

write_csv(types, "clean_data/FINAL_types_summary.csv")

#Include top 5 types by Count for plotting purposes
#The code below plots top five level 2 types
types5 <- types %>% arrange(desc(Count)) %>% filter(Count > 500)

ggplot(types5) + geom_col(aes(x = reorder(Name, desc(Count)), y = Count, fill = reorder(Name, desc(Count)))) + scale_fill_jco() +
  labs(x = "Level 2 Classification", y = "Number of Plots") + 
  theme_light() +
  theme(text = element_text(size = 18),legend.position = "none",axis.title.y = element_text(margin = margin(r = 10)), axis.title.x = element_text(margin = margin(t = 20)), axis.text.x = element_text(angle = -20)) +
  scale_x_discrete(labels = c("Complex Mixed","Multistrata Mixed with\nprimary Silver Maple","Complex Silver Maple\nwith Snag","Complex Silver Maple\nwith Cottonwood", "Multistrata Green Ash\nand Silver Maple"))
  
no_mixed <- types %>% arrange(desc(Count)) %>% filter(Count > 400, Type != "Mixed")

ggplot(no_mixed) + geom_col(aes(x = reorder(Name, desc(Count)), y = Count, fill = reorder(Name, desc(Count)))) + scale_fill_jco() +
  labs(x = "Level 2 Classification", y = "Number of Plots") + 
  theme_light() +
  theme(text = element_text(size = 18),legend.position = "none",axis.title.y = element_text(margin = margin(r = 10)), axis.title.x = element_text(margin = margin(t = 20)), axis.text.x = element_text(angle = -20)) +
  scale_x_discrete(labels = c("Complex Silver Maple\nwith Snag","Complex Silver Maple\nwith Cottonwood", "Multistrata Green Ash\nand Silver Maple", "Reinitiation Willow","Multistrata Snag and\nSilver Maple"))

#The code below performs a basic analysis and plotting of the five USDA structural stages by counting string occurrences
final <- read_csv("clean_data/FINAL_types_summary.csv")

sum(final[grepl("Initiation",final$Name),]$Count)

structures <- c("Initiation","Exclusionary","Reinitiation","Multistrata","Complex")

counts <- c(sum(final[grepl("Initiation",final$Name),]$Count),
  sum(final[grepl("Exclusionary",final$Name),]$Count),
  sum(final[grepl("Reinitiation",final$Name),]$Count),
  sum(final[grepl("Multistrata",final$Name),]$Count),
  sum(final[grepl("Complex",final$Name),]$Count))

df <- data.frame(Names = structures, Count = counts)
ggplot(df) + geom_col(aes(x = factor(Names, levels = structures), y = Count, fill = Names)) + scale_fill_jco() + theme_light() +
  labs(x = "Structural Stage", y = "Number of Plots") +
  theme(text = element_text(size = 18),legend.position = "none",axis.title.y = element_text(margin = margin(r = 10)), axis.title.x = element_text(margin = margin(t = 20)))

