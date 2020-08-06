#This script oversamples to duplicate and balance the level 2 types in the dataset to train a decision tree
#This approach winded up not being used (we used silhouette values instead) so it was scrapped

library(tidyverse)
library(vegclust)
library(rpart)
library(infotheo)
#Requires classification procedure
source("classification_procedure.R")

#Load dissimilarity matrix and specific forest type data
df <- load_data("ACSA2")
d <- read_csv("dissimilarity_matrix.csv")
cluster_h <- hclust(as.dist(d), method = "ward.D2")

plot_abundance <- df %>%
  group_by(PID, TR_SP) %>%
  summarize(TPA = sum(TreesPerAcre)) %>%
  replace(is.na(.), 0) 

plot_size <- df %>%
  group_by(PID, TR_SP) %>%
  summarize(BA = sum(BasalArea)) %>%
  replace(is.na(.), 0)

plots <- inner_join(plot_abundance, plot_size, by = c("PID", "TR_SP")) %>% 
  pivot_wider(names_from = TR_SP, values_from = c(TPA, BA)) %>% 
  replace(is.na(.), 0)

plots <- left_join(plots, read_csv("clean_data/plot_classification.csv"))
plots$cluster <- cutree(cluster_h, 4)

#Try oversampling

output <- filter(plots, cluster == which.max(table(plots$cluster)))
for(c in 1:length(unique(plots$cluster))){
  print(c)
  len <- max(table(plots$cluster)) - table(plots$cluster)[c]
  if(len == 0){next}
  
  plots_target <- filter(plots, cluster == c)
  target <- plots_target
  
  n <- floor(len / table(plots$cluster)[c])
  remain <- len %% table(plots$cluster)[c]
  
  target <- target[rep(seq_len(nrow(target)), n + 1), ]
  target <- rbind(target, plots_target[sample(1:nrow(plots_target), remain),])
  
  output <- rbind(output, target)
}
nrow(output)
output %>% group_by(cluster) %>% summarize(count = n())

max(table(plots$cluster)) * 5
#Works!

