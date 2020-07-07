##### Imports #####
# Clustering algorithm for mixed plots

library(tidyverse)
library(vegclust)
library(lubridate)
library(RFLPtools)
library(cluster)
library(rpart)
library(rpart.plot)
library(zoo)
library(vegan)

path_of_code <- rprojroot::find_rstudio_root_file()

df <- read_csv("clean_data/UMRS_FPF_clean.csv")
labels <- read_csv("clean_data/plot_classification.csv")
df_cols <- left_join(df, labels, by = "PID") %>% select(PID, TR_SP, TR_DIA, BasalArea, TreesPerAcre, Label)
mixed <- df_cols %>% filter(Label == 'Mixed')
load('cluster_h_d2.RData')
plots <- read_csv("clean_data/plots_full.csv")
source('Species_dictionary.R')
source('useful_functions.R')
source('plot_level_df.R')

theme_set(theme_gray(base_size = 10))

##### CAP #####
# Number of unique PIDs in mixed category
n_distinct(mixed$PID)

# Bins for CAP
TPA_bins <- 1 / (pi * (seq(1:106)*2.75)^2) / 43560
BA_bins <- 0.25*pi*(seq(1:106)^2)
DIA_bins <- 1:106

cap <- mixed %>% stratifyvegdata(sizes1 = DIA_bins, plotColumn = 'PID', speciesColumn = 'TR_SP', 
                                  abundanceColumn = 'TreesPerAcre', size1Column = 'TR_DIA',
                                  cumulative = T)

sort(unique(mixed$PID))

start <- now()
dissim <- vegdiststruct(cap, method = 'manhattan')
end <- now()
print(end - start)

# write_csv(as.data.frame(as.matrix(dissim)), 'mixed_dissim.csv')


##### Hierarchical clustering ######

dissim <- read_csv('mixed_dissim.csv')

# cluster_h <- hclust(as.dist(dissim), method = "ward.D")

start <- now()
cluster_h_d2 <- hclust(as.dist(dissim), method = "ward.D2")
save(cluster_h_d2, file = 'cluster_h_d2.RData')
saveRDS(cluster_h_d2, file = 'cluster_h_d2.rds')
print(now() - start)

start <- now()
cluster_h_d <- hclust(as.dist(dissim), method = "ward.D")
save(cluster_h_d, file = 'cluster_h_d.RData')
saveRDS(cluster_h_d, file = 'cluster_h_d.rds')
print(now() - start)

plot(cluster_h_d2, labels = F)
plot(cluster_h_d)



plot_classifier(plots %>% filter(PID == 'TBD'))

plots %>% filter(PID == 'TBD') %>% .$SNAG_rel_BA
plots %>% filter(PID == 'TBD') %>% .$PLOC_rel_TPA


# Saves cluster_h object so you dont have to run it again
# save(cluster_h, file = 'cluster_h.RData')
# saveRDS(cluster_h, file = 'cluster_h.rds')

plot(cluster_h)

cutree(cluster_h, k = 5)

##### Post-hierarchical clustering #####

plots_acsa <- read_csv("clean_data/plots_full.csv") %>% filter(is.na(Type))
form <- paste( "cluster ~", paste0(colnames(plots_acsa2)[2:(ncol(plots_acsa2)-2)], collapse = " + "))
n = 10
cut <- cutree(cluster_h, k = n)
clusters <- tibble(PID = sort(plots_acsa$PID), cluster = cut)
plots_acsa2 <- left_join(plots_acsa, clusters, by = 'PID')

tree <- rpart(data = plots_acsa2, formula = form, method = "class", 
              control = rpart.control(maxdepth = ceiling(log(n*2,2)), cp = 0, minbucket = 6))

result <- table(predict(tree, t="class"), plots_acsa2$cluster)
sum(diag(result)) / sum(result)

rpart.plot(tree)


results <- vector(length = 19)
for(n in 2:20){
  print(n)
  cut <- cutree(cluster_h, k = n)
  clusters <- tibble(PID = sort(plots_acsa$PID), cluster = cut)
  plots_acsa2 <- left_join(plots_acsa, clusters, by = 'PID')
  
  tree <- rpart(data = plots_acsa2, formula = form, method = "class",
                control = rpart.control(maxdepth = ceiling(log(n*2,2)), cp = 0, minbucket = 6))
  
  result <- table(predict(tree, t="class"), plots_acsa2$cluster)
  results[n-1] <- sum(diag(result)) / sum(result)
}
plot((seq(1:19)+1),results)

results <- vector(length = 19)
for(n in 2:20){
  print(n)
  cut <- cutree(cluster_h, k = n)
  clusters <- tibble(PID = sort(plots_acsa$PID), cluster = cut)
  plots_acsa2 <- left_join(plots_acsa, clusters, by = 'PID')
  
  tree <- rpart(data = plots_acsa2, formula = form, method = "class", 
                control = rpart.control(maxdepth = ceiling(log(n*2,2)), cp = 0, minbucket = 1))
  
  result <- table(predict(tree, t="class"), plots_acsa2$cluster)
  results[n-1] <- min(na.fill(diag(result) / rowSums(result), 0))
}
plot(seq(2:20),results[2:20])


## Silhouettes for different cuts

clusters <- 20
sil <- vector("list", length = clusters-1)
for(n in 2:clusters){
  sil[[n-1]] <- silhouette(x = cutree(cluster_h, k = n), dmatrix = as.matrix(dissim))
}

plot(sil[[4]], border = NA)


avg_widths <- vector(length = clusters-1)
for(n in 2:clusters){
  print(n)
  avg_widths[n-1] <- mean(sil[[n-1]][,3])
  }

df <- data.frame(seq(2:20),avg_widths, colnames = c("Clusters","Average Silhouette Length"))

qplot((seq(1:19) + 1), avg_widths) + theme_light() + xlab("Clusters") + ylab("Average Silhouette Width")

which.min(avg_widths)


##### PAM Clustering #####

clusts <- cutree(cluster_h, k = 5)

pam_cluster <- pam(dissim, k = 5, diss = T, medoid = clusts) 


##### Distribution of clusters #####

# Filters where only species that make up >= 1% of count show up
# most_abund_species <- mixed %>% count(TR_SP) %>% filter(n/sum(n) >= 0.01) %>% .$TR_SP 

# ~5% of individuals were filtered out
(mixed %>% count(TR_SP) %>% .$n %>% sum -
    mixed %>% count(TR_SP) %>% filter(n/sum(n) >= 0.01) %>% .$n %>% sum) /
  mixed %>% count(TR_SP) %>% .$n %>% sum


df_clust <- make_clusters(10, filter = T)
df_clust

species_multiplot(k = 10, leg_col = 1, pos = 'fill', clusters = cluster_h_d2, codes = F, filter = F)

# Histogram of TR_DIA in clusters (doesnt account for species)
dia_hist <- df_clust %>% ggplot(aes(x = TR_DIA)) +
  geom_histogram() +
  facet_wrap(~cluster, nrow = 2)
dia_hist

# Density plot of TR_DIA in clusters (doesnt account for species)
dia_dens <- df_clust %>% ggplot(aes(x = TR_DIA)) +
  geom_density() +
  facet_wrap(~cluster, nrow = 2)
dia_dens


species_multiplot(2, pos = 'stack', leg_col = 1)
tpa_ba_multiplot(2)


##### CAP of Clusters #####

k = 2
df_clust <- make_clusters(k, filter = F)

df_clust %>% group_by(cluster, PID) %>% summarize(count = n()) %>% summarize(count= n())
?count

df_clust %>% count(cluster)

DIA_bins <- 1:106

cluster_cap <- df_clust %>% stratifyvegdata(sizes1 = DIA_bins, plotColumn = 'cluster', speciesColumn = 'TR_SP', 
                                            abundanceColumn = 'TreesPerAcre', size1Column = 'TR_DIA',
                                            cumulative = T)
# cluster_cap

start <- now()
cluster_dissim <- vegdiststruct(cluster_cap, method = 'manhattan')
end <- now()
print(end - start)
# cluster_dissim

cluster_hclust <- hclust(dist(cluster_dissim), method = 'ward.D2')

plot(cluster_hclust)


plot_CAP(cluster_cap, layout = matrix(c(1,1,3, 1,1,3,2,2,3,2,2,3),
                                      nrow = 4, ncol = 3, byrow = T), norm = T, xlims = NULL, leg = F)



source('useful_functions.R')


##### Ordination #####

k <- 10

df_clust <- make_clusters(k = 10, filter = F) %>% group_by(cluster)
clust_sample <- df_clust %>% sample_n(size = 75)

sample_cap <- clust_sample %>% stratifyvegdata(sizes1 = DIA_bins, plotColumn = 'PID', speciesColumn = 'TR_SP', 
                                               abundanceColumn = 'TreesPerAcre', size1Column = 'TR_DIA',
                                               cumulative = T)

start <- now()
sample_dissim <- vegdiststruct(sample_cap, method = 'manhattan')
end <- now()
print(end - start)

dist(sample_dissim)

sample_MDS <- metaMDS(as.dist(sample_dissim), trymax = 100)

sample_MDS$species

sample_dissim

summary_stats(11)$num_plots %>% sum()


##### Finding best clusters #####

best_clustering <- function(df, dissim, max_clusters, meth = "ward.D2"){
  
  cluster_h <- hclust(as.dist(dissim), method = meth)
  print(1)
  plot_abundance <- df %>%
    group_by(PID, TR_SP) %>%
    summarize(TPA = sum(TreesPerAcre), BA = sum(BasalArea)) %>%
    replace(is.na(.), 0) 
  print(2)
  print(3)
  plots <- plot_abundance %>% 
    pivot_wider(names_from = TR_SP, values_from = c(TPA, BA)) %>% 
    replace(is.na(.), 0)
  print(4)
  plots <- left_join(plots, read_csv("clean_data/plot_classification.csv"))
  #form <- paste( "cluster ~", paste0(colnames(plots)[2:(ncol(plots)-2)], collapse = " + "))
  print(5)
  num <- min(max_clusters, nrow(plots))
  print(6)
  sil <- vector("list", length = num-1)
  for(n in 2:num){
    print(n)
    plots$cluster <- cutree(cluster_h_d2, k = n)
    sil[[n-1]] <- mean(silhouette(x = plots$cluster, dmatrix = as.matrix(dissim))[,"sil_width"])
  }
  print(sil)
  plots$cluster <- cutree(cluster_h, k = (which.max(sil)+1))
  return(plots)
}

clustering <- best_clustering(mixed, dissim, 10)

plot_abundance <- mixed %>%
  group_by(PID, TR_SP) %>%
  summarize(TPA = sum(TreesPerAcre), BA = sum(BasalArea)) %>%
  replace(is.na(.), 0) 

plots <- plot_abundance %>% 
  pivot_wider(names_from = TR_SP, values_from = c(TPA, BA)) %>% 
  replace(is.na(.), 0)

plot_abundance

plots

clustering$cluster %>% unique()
