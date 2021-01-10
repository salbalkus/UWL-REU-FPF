#This script performs k-fold cross-validation to determine the robustness of our solution
#It uses the clustering procedure from classification_procedure_cluster.R
#It stores data for later use

library(tidyverse)
library(ggsci)
library(grid)
library(gridExtra)

path_of_code <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(path_of_code)

source("classification_procedure_cluster.R")
setwd("..")


#Overwrite method for classifying

classify <- function(max_clusters_num, fold, folds){
  #Load original cleaned data and the data for the level 1 classification
  df <- read_csv("clean_data/UMRS_FPF_clean.csv")
  labels <- read_csv("clean_data/plot_classification.csv")
  df <- left_join(df, labels, by = "PID")
  df <- df[-which(1:nrow(df) < round(nrow(df) / folds)*fold & 1:nrow(df) > round(nrow(df) / folds)*(fold-1)) ,]
  df_cols_total <- df  %>% filter(Type %in% (df %>% group_by(Type) %>% summarize(Count = n_distinct(PID)) %>% filter(Count > 10))$Type)

  
  #Set up the data frame with the first possible level 1 class
  df_small <- df %>% filter(Type =="ACNE2")
  dissim <- dissimilarity_matrix(df_small)
  result <- best_clustering(df_small, dissim, 10)
  
  #Perform clustering on all other level 1 classes and append to the first classification.
  
  for(dom_species in unique(df_cols_total$Type)[unique(df_cols_total$Type) != "ACNE2"]){
    print(dom_species)
    df_small <- df %>% filter(Type == dom_species)
    dissim <- dissimilarity_matrix(df_small)
    best <- best_clustering(df_small, dissim, 10)
    result <- rbind(result, best)
    
  }
  
  return(result)
}

folds <- 5
for(fold in 1:folds) {

  final <- classify(10, fold, folds)
  new_final <- final %>% select(PID, Type, Label, cluster)
  
  write_csv(final, paste("clean_data/classified_plots_crossval_", fold, ".csv", sep = ""))
  write_csv(new_final, paste("clean_data/classified_plots_crossval_labels_", fold, ".csv", sep = ""))
}