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

theme_set(theme_gray(base_size = 30))

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

write_csv(as.data.frame(as.matrix(dissim)), 'mixed_dissim.csv')


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

tree <- rpart(data = plots_acsa2, formula = form, method = "class", control = rpart.control(maxdepth = ceiling(log(n*2,2)), cp = 0, minbucket = 6))

result <- table(predict(tree, t="class"), plots_acsa2$cluster)
sum(diag(result)) / sum(result)

rpart.plot(tree)


results <- vector(length = 19)
for(n in 2:20){
  print(n)
  cut <- cutree(cluster_h, k = n)
  clusters <- tibble(PID = sort(plots_acsa$PID), cluster = cut)
  plots_acsa2 <- left_join(plots_acsa, clusters, by = 'PID')
  
  tree <- rpart(data = plots_acsa2, formula = form, method = "class", control = rpart.control(maxdepth = ceiling(log(n*2,2)), cp = 0, minbucket = 6))
  
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
  
  tree <- rpart(data = plots_acsa2, formula = form, method = "class", control = rpart.control(maxdepth = ceiling(log(n*2,2)), cp = 0, minbucket = 1))
  
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


multiplot <- function(..., plotlist=NULL, file, cols=1, layout=NULL) {
  library(grid)
  
  # Make a list from the ... arguments and plotlist
  plots <- c(list(...), plotlist)
  
  numPlots = length(plots)
  
  # If layout is NULL, then use 'cols' to determine layout
  if (is.null(layout)) {
    # Make the panel
    # ncol: Number of columns of plots
    # nrow: Number of rows needed, calculated from # of cols
    layout <- matrix(seq(1, cols * ceiling(numPlots/cols)),
                     ncol = cols, nrow = ceiling(numPlots/cols))
  }
  
  if (numPlots==1) {
    print(plots[[1]])
    
  } else {
    # Set up the page
    grid.newpage()
    pushViewport(viewport(layout = grid.layout(nrow(layout), ncol(layout))))
    
    # Make each plot, in the correct location
    for (i in 1:numPlots) {
      # Get the i,j matrix positions of the regions that contain this subplot
      matchidx <- as.data.frame(which(layout == i, arr.ind = TRUE))
      
      print(plots[[i]], vp = viewport(layout.pos.row = matchidx$row,
                                      layout.pos.col = matchidx$col))
    }
  }
}

# Filters where only species that make up >= 1% of count show up
most_abund_species <- mixed %>% count(TR_SP) %>% filter(n/sum(n) >= 0.01) %>% .$TR_SP 

# ~5% of individuals were filtered out
(mixed %>% count(TR_SP) %>% .$n %>% sum -
    mixed %>% count(TR_SP) %>% filter(n/sum(n) >= 0.01) %>% .$n %>% sum) /
  mixed %>% count(TR_SP) %>% .$n %>% sum

# This function will make the clusters according to the hierarchical clustering algorithm we
# ran earlier.  It will add a clusters column to the individual-level dataframe (df)
# The primary arguments that should be altered are k and filter.  k is the number of clusters
# to make, and filter will only include species that make up at least 1% of the total count
# across all individuals
make_clusters <- function(k, clusters = cluster_h_d2, tot_df = df, mixed_df = mixed,
                          species_abund = most_abund_species, filter = T){
  
  # Joins clusters with PIDs
  pid_clusts <- rownames_to_column(as.data.frame(cutree(clusters, k = k)), 'PID')
  colnames(pid_clusts)[2] <- 'cluster'
  
  # Creates a tibble with cluster and info about individual trees
  if (!filter){
  df_clust <- left_join(tot_df %>% filter(PID %in% unique(mixed$PID)), pid_clusts, by = 'PID')
  }
  
  # This creates a different table, where it filters so only the most abundant species are 
  # selected.  It uses the same name for ease of using plotting code
  if (filter){
  df_clust <- left_join(df %>% filter(PID %in% unique(mixed$PID)), pid_clusts, by = 'PID') %>% 
    filter(TR_SP %in% most_abund_species)
  }
  
  # Returns df_clust object
  return(df_clust)
}


# This function generates a multiplot with the species distribution for count, tpa,
# and ba.  The k and filter arguments are passed on to make_clusters.  The pos argument
# determines the type of bar chart (either 'fill', 'stack', or 'dodge').  The mplot
# argument will generate a multiplot if true or return a list of the plots if false
species_multiplot <- function(k = 10, pos = 'fill', filter = T, mplot = T, leg_col = 3, codes = F,
                              clusters = cluster_h_d2, legend = T){
  df_clust <- make_clusters(k = k, filter = filter, clusters = clusters)
  sp_summary <- df_clust %>% group_by(cluster, TR_SP) %>% 
    summarize(count = n(), tpa = sum(TreesPerAcre), ba = sum(BasalArea)) 
  if (!codes) {sp_summary <- sp_summary %>% mutate(Species = read_dict(TR_SP))}
  if (codes) {sp_summary <- sp_summary %>% mutate(Species = TR_SP)}

  # Bar chart showing distribution of each species in each cluster
  sp_bar <- sp_summary %>%  ggplot(aes(x = cluster, y = count, fill = Species)) +
    geom_bar(stat = 'identity', position = pos) +
    theme(legend.position = 'none', axis.ticks.y = element_blank()) + 
    scale_x_continuous(breaks = 1:k) + 
    scale_y_continuous(labels = NULL) +
    labs(x = 'Cluster', y ='Count')
  # sp_bar

  # Shows total TPA by species in each cluster
  sp_tpa <- sp_summary %>%  ggplot(aes(x = cluster, y = tpa, fill = Species)) +
    geom_bar(position = pos, stat = 'identity') +
    theme(legend.position = 'none', axis.ticks.y = element_blank()) + 
    scale_x_continuous(breaks = 1:k) + 
    scale_y_continuous(labels = NULL) +
    labs(x = "Cluster", y = 'Trees per Acre')
  # sp_tpa

  # Shows total BA by species in each cluster
  if (legend) leg_pos <- 'left'
  if (!legend) leg_pos <- 'none'
  
  sp_ba_leg <- sp_summary %>% ggplot(aes(x = cluster, y = ba, fill = Species)) +
    geom_bar(position = pos, stat = 'identity') +
    theme(legend.position = leg_pos) + 
    guides(fill = guide_legend(ncol = leg_col)) 

  sp_ba <- sp_summary %>%  ggplot(aes(x = cluster, y = ba, fill = Species)) +
    geom_bar(position = pos, stat = 'identity') +
    theme(legend.position = 'none', axis.ticks.y = element_blank()) + 
    scale_x_continuous(breaks = 1:k) + 
    scale_y_continuous(labels = NULL) +
    labs(x = 'Cluster', y = 'Basal Area')
  # sp_ba

  # Grabs legend from plot for the multiplot function
  sp_legend <- ggpubr::as_ggplot(ggpubr::get_legend(sp_ba_leg))
  # sp_legend

  if (mplot){
  multiplot(plotlist = list(sp_bar, sp_tpa, sp_ba, sp_legend),
            cols = 2, layout = matrix(c(1,2,3,4), nrow=2, byrow=TRUE))
  }

  if (!mplot){
    return(list(sp_bar, sp_tpa, sp_ba, sp_legend))
  }
}

species_multiplot(k = 3, leg_col = 1, pos = 'fill', clusters = cluster_h_d2, codes = T, filter = F)
# This functions exactly like the species multiplot in terms of arguments.  It 
# will generate a multiplot with average tpa and ba across clusters to look for any patterns
tpa_ba_multiplot <- function(k = 10, filter = T, mplot = T, clusters = cluster_h){
  df_clust <- make_clusters(k = k, filter = filter, clusters = clusters)
  
  tpa_ba_sum <- df_clust %>% group_by(cluster) %>% 
    summarize(tpa = mean(TreesPerAcre), ba = mean(BasalArea))
  
  # Makes plots for both tpa and ba
  tpa_plot <- tpa_ba_sum %>% ggplot() + 
    geom_col(aes(x = cluster, y = tpa)) + 
    scale_x_continuous(breaks = 1:k)
  ba_plot <- tpa_ba_sum %>% ggplot() + 
    geom_col(aes(x = cluster, y = ba)) + 
    scale_x_continuous(breaks = 1:k)

  if (mplot) multiplot(tpa_plot, ba_plot)

  if (!mplot){
   return(list(tpa_plot, ba_plot)) 
  }
  
}


df_clust <- make_clusters(10)
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

left_join(mixed, as.data.frame(cutree(cluster_h_d2, k = 3)))

read_dict('FOAC')
rownames(as.data.frame(cutree(cluster_h_d2, k = 3)))
    

species_multiplot(10, pos = 'stack', leg_col = 1)
tpa_ba_multiplot(10)


##### CAP of Clusters #####

k = 10
df_clust <- make_clusters(k, filter = T)
DIA_bins <- 1:106

cluster_cap <- df_clust %>% stratifyvegdata(sizes1 = DIA_bins, plotColumn = 'cluster', speciesColumn = 'TR_SP', 
                                            abundanceColumn = 'TreesPerAcre', size1Column = 'TR_DIA',
                                            cumulative = T)
  
cluster_cap

start <- now()
cluster_dissim <- vegdiststruct(cluster_cap, method = 'manhattan')
end <- now()
print(end - start)

cluster_dissim

cluster_hclust <- hclust(dist(cluster_dissim), method = 'ward.D2')

plot(cluster_hclust)

plot_CAP <- function(cap, x_lim = c(0, 40), mplot = T, plot_col = 4, layout = NULL){
  plots <- list()
  for (i in 1:length(cap)){
    ggplot_df <- as_tibble(t(as.matrix(cluster_cap[[i]]))) %>% mutate(low_bound = 0:104) %>% 
      gather(-low_bound, key = TR_SP, value = CAP)
    
    cap_plot <- ggplot_df %>% ggplot(aes(x = low_bound, y = CAP)) +
      geom_step(aes(color = TR_SP), direction = 'hv') + 
      xlim(x_lim) + 
      theme_gray() +
      theme(legend.position = 'none', axis.ticks.y = element_blank(),
            plot.title = element_text(size = 25)) +
      scale_y_continuous(labels = NULL, limits = c(0, 75000)) + 
      labs(x = NULL, y = NULL, title = paste('Cluster', i, sep = ' '))
      
      
    plots[[i]] <- cap_plot
  }
  
  ggplot_df <- as_tibble(t(as.matrix(cluster_cap[[i]]))) %>% mutate(low_bound = 0:104) %>% 
    gather(-low_bound, key = TR_SP, value = CAP)
  
  cap_plot <- ggplot_df %>% ggplot(aes(x = low_bound, y = CAP, fill = TR_SP)) +
    geom_col() + 
    ylim(0, 75000) +
    theme_gray() + 
    theme(legend.title = element_text(size = 30), legend.text = element_text(size = 25))
    
  cap_legend <- ggpubr::as_ggplot(ggpubr::get_legend(cap_plot))
  
  plots[[length(cap) + 1]] <- cap_legend
  
  if (mplot) {
    multiplot(plotlist = plots, cols = plot_col, layout = layout)
  }
  if (!mplot) return(plots)
}
layout = matrix(c(1,2,3,4,5,6,7,11,8,9,10,11), nrow = 3, byrow = T)
plot_CAP(cluster_cap, layout = layout)

df_clust %>% filter(cluster == 4) %>% .$PID %>% n_distinct

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

sample_MDS <- metaMDS(dist(sample_dissim), trymax = 100)

sample_MDS$species

sample_dissim



