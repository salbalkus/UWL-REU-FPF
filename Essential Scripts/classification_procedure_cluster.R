#This script provides the functions necessary to create the level 2 classes using Ward's clustering and silhouette plots
#It is called by other scripts in our project, and it requires the original clean data as well as the labels for the level 1 classes.

library(tidyverse, quietly = TRUE)
library(vegclust, quietly = TRUE)
library(rpart, quietly = TRUE)
library(infotheo, quietly = TRUE)
library(cluster, quietly = TRUE)


#Load in the data that will be used for clustering
load_data <- function(dom_species){

  df <- read_csv("clean_data/UMRS_FPF_clean.csv")
  labels <- read_csv("clean_data/plot_classification.csv")

  df_cols <- left_join(df, labels, by = "PID") %>% select(PID, TR_SP, TR_DIA, BasalArea, TreesPerAcre, Type, Label) %>% filter(Type == dom_species)
  return(df_cols)
}

#Produce the dissimilarity matrix for the given dominant species type
dissimilarity_matrix <- function(df, meth = "manhattan"){
  #106 is the max... for some reason only works if 106 is hardcoded
  TPA_bins = 1 / (pi * (seq(1:106)*2.75)^2) / 43560
  BA_bins = 0.25*pi*(seq(1:106)^2)
  
  cap <- stratifyvegdata(df, sizes1 = BA_bins, plotColumn = "PID", speciesColumn = "TR_SP", abundanceColumn = "TreesPerAcre", size1Column = "BasalArea", cumulative = TRUE )
  d <- vegdiststruct(cap, method = meth)
  return(d)
}

#This function provides the best possible clustering solution for a single level 1 type and returns the data frame, labeled
best_clustering <- function(df, dissim, max_clusters, meth = "ward.D2"){
  
  cluster_h <- hclust(as.dist(dissim), method = meth)
  
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
  #form <- paste( "cluster ~", paste0(colnames(plots)[2:(ncol(plots)-2)], collapse = " + "))
  
  num <- min(max_clusters, nrow(plots))
  
  sil <- vector("list", length = num-1)
  for(n in 2:num){
    plots$cluster <- cutree(cluster_h, k = n)
    sil[[n-1]] <- mean(silhouette(x = plots$cluster, dmatrix = as.matrix(dissim))[,"sil_width"])
  }
  plots$cluster <- cutree(cluster_h, k = (which.max(sil)+1))
  return(plots)
}

#This function applies the best_clustering function to all possible level 1 classes and outputs a data frame.
classify <- function(max_clusters_num){
  #Load original cleaned data and the data for the level 1 classification
  df <- read_csv("clean_data/UMRS_FPF_clean.csv")
  labels <- read_csv("clean_data/plot_classification.csv")
  df <- left_join(df, labels, by = "PID")
  df_cols_total <- df  %>% filter(Type %in% (df %>% group_by(Type) %>% summarize(Count = n_distinct(PID)) %>% filter(Count > 10))$Type)
  
  #Set up the data frame with the first possible level 1 class
  df <- load_data("ACNE2")
  dissim <- dissimilarity_matrix(df)
  result <- best_clustering(df, dissim, 10)
  
  #Perform clustering on all other level 1 classes and append to the first classification.

  for(dom_species in unique(df_cols_total$Type)[unique(df_cols_total$Type) != "ACNE2"]){
    print(dom_species)
    df <- load_data(dom_species)
    dissim <- dissimilarity_matrix(df)
    best <- best_clustering(df, dissim, 10)
    result <- rbind(result, best)

  }
  
  return(result)
}

#Code for silhouette plot - to use, change the "best_clustering" function to output the silhouette values instead of the "plots" object 

#df <- load_data("ACSA2 and SALIX")
#dissim <- dissimilarity_matrix(df)
#sil <- best_clustering(df, dissim, 10)

#plot(seq(1:9)+1, sil, ylab = "Average Silhouette Value", xlab = "Number of Clusters")
#lines(seq(1:9)+1, sil)
#axis(side = 1, at = c(2,3,4,5,6,7,8,9,10),labels = c(2,3,4,5,6,7,8,9,10))

#Code for running the classification and plotting results:

final <- classify(10)
unique(new_final$Label)
new_final <- final %>% select(PID, Type, Label, cluster)
write_csv(final, "clean_data/classified_plots_full.csv")
write_csv(new_final, "clean_data/classified_plots_labels.csv")


