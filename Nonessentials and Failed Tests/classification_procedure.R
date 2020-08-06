#This script defines the procedure for level 2 classification that uses the decision tree and vmeasure to select number of classes.
#This procedure has since been scrapped in favor of silhouette values.

library(tidyverse, quietly = TRUE)
library(vegclust, quietly = TRUE)
library(rpart, quietly = TRUE)
library(infotheo, quietly = TRUE)


#Load in the data that will be used for clustering
load_data <- function(dom_species){

  df <- read_csv("clean_data/UMRS_FPF_clean.csv")
  labels <- read_csv("clean_data/plot_classification.csv")

  df_cols <- left_join(df, labels, by = "PID") %>% select(PID, TR_SP, TR_DIA, BasalArea, TreesPerAcre, Type, Label) %>% filter(Type == dom_species)
  return(df_cols)
}

#Produce the dissimilarity matrix for the given dominant species type
dissimilarity_matrix <- function(df, meth = "manhattan"){
  
  TPA_bins = 1 / (pi * (seq(1:max(df$TR_DIA))*2.75)^2) / 43560
  BA_bins = 0.25*pi*(seq(1:max(df$TR_DIA))^2)
  
  cap <- stratifyvegdata(df, sizes1 = BA_bins, plotColumn = "PID", speciesColumn = "TR_SP", abundanceColumn = "TreesPerAcre", size1Column = "BasalArea", cumulative = TRUE )
  d <- vegdiststruct(cap, method = meth)
  return(d)
}

oversample <- function(plots){
  output <- filter(plots, cluster == which.max(table(plots$cluster)))
  for(c in 1:length(unique(plots$cluster))){
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
  return(output)
}

#Classification output for a single dominant species type
#This needs to be tested, and introspection must be able to be performed
best_clustering <- function(df, dissim, dom_species, max_clusters, os = FALSE, meth = "ward.D2"){
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
  form <- paste( "cluster ~", paste0(colnames(plots)[2:(ncol(plots)-2)], collapse = " + "))
  
  vmeasures <- vector(length = max_clusters - 1)
  trees <- vector("list",length = max_clusters - 1)
  for(n in 2:max_clusters){
    cut <- cutree(cluster_h, k = n)
    plots$cluster <- cut
    if(os){
      new_plots <- oversample(plots)
    }
    else {
      new_plots <- plots
    }
    trees[[n-1]] <- rpart(data = new_plots, formula = form, method = "class", control = rpart.control(maxdepth = ceiling(log(2*n,2)), cp = 0, minbucket = 1))
    sel_tree <- trees[[n-1]]
    new_plots$tree <- predict(sel_tree, new_plots, type = "vector")
    #Should this be using the oversampled df or the previous df?
    h <- 1 - condentropy(new_plots$cluster, new_plots$tree) / entropy(new_plots$cluster)
    c <- 1 - condentropy(new_plots$tree, new_plots$cluster) / entropy(new_plots$tree)
    
    vmeasures[n-1] <- 2 * ((h*c) / (h + c))
  }
  
  best_k <- which.max(vmeasures)
  
  plots$cluster <- predict(trees[[best_k]], plots, type = "vector")
  return(list(plots, trees[[best_k]]))
}

