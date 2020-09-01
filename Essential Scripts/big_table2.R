#The purpose of this script is to take the developed classification system and produce some basic summary statistics
#at the plot level and at the class level. It is one of the final scripts in our analysis.

library(tidyverse)

path_of_code <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(path_of_code)
setwd("..")

#Load the following:
# Forest labels for each plot
# Level 2 class names for each class
# Original cleaned data file

level1 <- read_csv("clean_data/plot_classification.csv")
level2 <- read_csv("clean_data/classified_plots_labels.csv")
data <- read_csv("clean_data/UMRS_FPF_clean.csv")



#Label the data frame with the forest classification system
labels <- left_join(level1, level2, by = c("PID","Type","Label"))
labels[is.na(labels$cluster),]$cluster <- 1
plots <- left_join(data, labels, by = c("PID"))
plots$Name <- paste(plots$Type, plots$cluster, sep = ".")

#plots$TR_DIA[plots$TR_SP == word(plots$Type, 1)]

plots

stats <- plots %>% group_by(Name) %>% 
  summarize(Num_Plots = n_distinct(PID),
            First_Species_DBH = median(TR_DIA[TR_SP == word(Type, 1)]),
            First_Species_TPA = median(TreesPerAcre[TR_SP == word(Type, 1)]),
            Second_Species_DBH = median(TR_DIA[TR_SP == word(Type, 3)]),
            Second_Species_TPA = median(TreesPerAcre[TR_SP == word(Type, 3)]),
            Nav_Pools = n_distinct(POOL)
            )

#plots[plots$Name == "ACNE2 and ACSA2.1",]

stats

stats_plot_level <- plots %>% group_by(Name, PID) %>%
  summarize(Plot_DBH = 10 * n(),
            Species = n_distinct(TR_SP),
            TPA = sum(TreesPerAcre),
            rel_SNAG_TPA = sum(TreesPerAcre[TR_SP == "SNAG"]) / TPA,
            rel_V_TPA = sum(TreesPerAcre[TR_HLTH == "V"]) / TPA,
            rel_S_TPA = sum(TreesPerAcre[TR_HLTH == "S"]) / TPA,
            rel_SD_TPA = sum(TreesPerAcre[TR_HLTH == "SD"]) / TPA,
            ) %>%
  group_by(Name) %>%
  summarize(Median_Plot_DBH = median(Plot_DBH),
            Median_Species = median(Species),
            MP_relTPA_SNAG = median(rel_SNAG_TPA),
            MP_relTPA_V = median(rel_V_TPA),
            MP_relTPA_S = median(rel_S_TPA),
            MP_relTPA_SD = median(rel_SD_TPA)
            
  )

stats <- left_join(stats, stats_plot_level, by = "Name")
write_csv(stats, "class_statistics.csv")











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

