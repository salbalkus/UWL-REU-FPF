#This script performs an robustness analysis of how closely the k-fold cluster solution matched the "true," overall clustering solution
#To do this, we use the "purity" which measures the percentage of plots that were correctly placed together. 
#The closer the purity is to 1, the better. A purity of 1 means that that every plot that was a part of the same class in the "true" Level 1 group was 
# assigned to a group with the same classes in the cross validated Level 1 groups.

library(tidyverse)
library(ggsci)
library(grid)
library(gridExtra)
library(funtimes)

path_of_code <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(path_of_code)
setwd("..")


full <- read_csv("clean_data/classified_plots_labels.csv")
total_purity <- data.frame()

#For each fold, calculate the purity for each Level 1 class
for(i in 1:5) {
  fold <- read_csv(paste("clean_data/classified_plots_crossval_labels_", i, ".csv", sep = ""))
  df <- left_join(full, fold, by = c("PID", "Type", "Label"))
  df <- drop_na(df)
  purity_scores <- df %>% group_by(Type, Label) %>% summarize(pure = purity(cluster.x, cluster.y)$pur)
  purity_scores$fold_omitted <- i
  total_purity <- rbind(total_purity, purity_scores)
}

write_csv(total_purity, "clean_data/purity_scores.csv")

#Calculate the average purity across folds for each Level 1 classes
avg_total_purity <- total_purity %>% group_by(Type, Label) %>% summarize(purity <- mean(pure))

write_csv(avg_total_purity, "clean_data/avg_purity_scores.csv")

#Average of the averages - an overall meaure of purity
mean(avg_total_purity$`purity <- mean(pure)`)

#Other analyses
sum(avg_total_purity[,3] == 1) #Level 1 classes with perfect purity
sum(avg_total_purity[,3] == 1) / nrow(avg_total_purity)
     
avg_total_purity
counts <- full %>% group_by(Type, Label) %>% summarize(count = n())
avg_total_purity <- left_join(counts, avg_total_purity) %>% arrange(desc(count))

avg_total_purity
result <- ggplot(avg_total_purity[1:10,]) + geom_col(aes(x = reorder(Type, -count), y = `purity <- mean(pure)`), fill = "gray") +
  labs(x = "Level 1 Class", y = "Purity") + 
  theme_light() + 
  theme(axis.text.x = element_text(angle = 50, hjust = 0.5, vjust = 0.5), axis.title.x = element_text(margin = margin(t = 10)), axis.title.y = element_text(margin = margin(r = 10)))
ggsave("images/Top 10 Purity.png", result, device = "png")
