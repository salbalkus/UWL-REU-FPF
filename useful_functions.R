##### imports ######

library(tidyverse)

df <- read_csv("clean_data/UMRS_FPF_clean.csv")
labels <- read_csv("clean_data/plot_classification.csv")
df_cols <- left_join(df, labels, by = "PID") %>% select(PID, TR_SP, TR_DIA, BasalArea, TreesPerAcre, Label)
mixed <- df_cols %>% filter(Label == 'Mixed')
load('cluster_h_d2.RData')
source('Species_dictionary.R')


###### function for plotting #####

most_abund_species <- function(df, thresh = 0.01) df %>% count(TR_SP) %>% filter(n/sum(n) >= thresh) %>% .$TR_SP 

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

# This function will make the clusters according to the hierarchical clustering algorithm we
# ran earlier.  It will add a clusters column to the individual-level dataframe (df)
# The primary arguments that should be altered are k and filter.  k is the number of clusters
# to make, and filter will only include species that make up at least 1% of the total count
# across all individuals

labels$Type %>% unique()

labels %>% filter(is.na(Ty))

# this function will take the df at the individual tree level and add a column to determine which 
# cluster the tree is in based off of the PID
# the arguments are:
# k: the number of clusters
# clusters: the cluster object from the hclust() function
# tot_df: the total df at the tree level
# label_df: df that has label for each plot based off of level 1 classification
# type_filter: the type that the clusters object is based off of
# species_abund: species abundance function to filter the df
#     only used if filter = T
# filter: whether or not to filter the output df based on species abundance
#     i.e. if we want to only look at the common species
# filt_thresh: what percentage should species make up to be past the threshold for filtering
# codes: T display species codes in legend, F display species names in legend
make_clusters <- function(k, clusters = cluster_h_d2, tot_df = df, label_df = labels, type_filter = NA,
                          species_abund = most_abund_species, filter = T, filt_thresh = 0.01,
                          codes = T){
  

  # Joins clusters with PIDs
  pid_clusts <- rownames_to_column(as.data.frame(cutree(clusters, k = k)), 'PID')
  colnames(pid_clusts)[2] <- 'cluster'
  
  if (is.na(type_filter)) pids <- label_df %>% filter(is.na(Type)) %>% .$PID %>% unique()
  else pids <- label_df %>% filter(Type == type_filter) %>% .$PID %>% unique()
  
  filt_df <- tot_df %>% filter(PID %in% pids)
  
  # Creates a tibble with cluster and info about individual trees
  if (!filter){
    df_clust <- left_join(filt_df, pid_clusts, by = 'PID')
  }
  
  # This creates a different table, where it filters so only the most abundant species are 
  # selected.  It uses the same name for ease of using plotting code
  if (filter){
    df_clust <- left_join(filt_df, pid_clusts, by = 'PID') %>% 
      filter(TR_SP %in% most_abund_species(filt_df, thresh = filt_thresh))
  }
  
  if (codes) df_clust <- df_clust %>% mutate(Species = TR_SP)
  if (!codes) df_clust <- df_clust %>% cbind(Species = read_dict(df_clust$TR_SP))
  
  
  # Returns df_clust object
  return(df_clust)
}



# This function generates a multiplot with the species distribution for count, tpa,
# and ba.  The k and filter arguments are passed on to make_clusters.  The pos argument
# determines the type of bar chart (either 'fill', 'stack', or 'dodge').  The mplot
# argument will generate a multiplot if true or return a list of the plots if false
# legend decides whether or not to display the legend. 
# leg_col determines the number of columns in the legend
species_multiplot <- function(k = 10, pos = 'fill', clusters = cluster_h_d2,
                              tot_df = df, label_df = labels, type_filter = NA,
                              species_abund = most_abund_species, filter = T,
                              filt_thresh = 0.01, codes = F, mplot = T, legend = T,
                              leg_col = 3){
  
  df_clust <- make_clusters(k = k, tot_df = tot_df, label_df = label_df, 
                            type_filter = type_filter, species_abund = species_abund,
                            filter = filter, clusters = clusters, codes = codes)
  
  sp_summary <- df_clust %>% group_by(cluster, Species) %>% 
    summarize(count = n(), tpa = sum(TreesPerAcre), ba = sum(BasalArea)) 
  
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


# This will output a facet_wrap density plot of the diameter distributions grouped by species
# the main argument that is different is species, which has a default of NULL.  If you set
# species to a character vector, it will only plot those species
species_dia <- function(k = 10, species = NULL, clusters = cluster_h_d2,
                        tot_df = df, label_df = labels, type_filter = NA,
                        species_abund = most_abund_species, filter = T,
                        filt_thresh = 0.01, codes = T, ncol = 3){
  
  df_clust <- make_clusters(k = k, tot_df = tot_df, label_df = label_df, 
                            type_filter = type_filter, species_abund = species_abund,
                            filter = filter, clusters = clusters, codes = codes)

  if (!is.null(species)){
    df_clust <- df_clust %>% filter(TR_SP %in% species)
  }
  
  p <- df_clust %>% ggplot(aes(x = TR_DIA, color = Species)) +
    geom_density() +
    scale_y_sqrt(labels = NULL) +
    facet_wrap(~cluster, ncol = ncol) +
    theme(legend.position = 'bottom', axis.ticks.y = element_blank(),
          strip.text = element_text(size = 10))
  
  return(p)
  
}

# This functions exactly like the species multiplot in terms of arguments.  It 
# will generate a multiplot with average tpa and ba across clusters to look for any patterns
tpa_ba_multiplot <- function(k = 10, mplot = T, clusters = cluster_h_d2,
                             tot_df = df, label_df = labels, type_filter = NA,
                             species_abund = most_abund_species, filter = T,
                             filt_thresh = 0.01, codes = T){
  
  df_clust <- make_clusters(k = k, tot_df = tot_df, label_df = label_df, 
                            type_filter = type_filter, species_abund = species_abund,
                            filter = filter, clusters = clusters, codes = codes)
  
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

# This function takes in the output of a cap by cluster level.  The arguments are:
# xlims/ylims: set limits for x and y axis
# ylab: labels for the y axis.  Set to element blank to not have them
# mplot: output as multiplot or list of plots
# plot_col: how many columns in the plot
# layout: layout of plots in matrix form
# normalize: normalize values for each cluster 
#   (within each cluster divide by the max value)
# legend: show the legend
plot_CAP <- function(cap, xlims = c(0, 40), ylab = waiver(), ylims = NULL,
                     mplot = T, plot_col = 4, layout = NULL,
                     normalize = T, legend = T, ...){
  plots <- list()
  for (i in 1:length(cap)){
    ggplot_df <- as_tibble(t(as.matrix(cluster_cap[[i]]))) %>% mutate(low_bound = 0:104) %>% 
      gather(-low_bound, key = TR_SP, value = CAP)
    
    if (normalize) ggplot_df$CAP <- ggplot_df$CAP/max(ggplot_df$CAP)
    
    cap_plot <- ggplot_df %>% ggplot(aes(x = low_bound, y = CAP)) +
      geom_step(aes(color = TR_SP), direction = 'hv') + 
      # xlim(x_lim) + 
      theme_gray() +
      theme(legend.position = 'none', axis.ticks.y = element_blank(),
            plot.title = element_text(size = 25)) +
      scale_y_sqrt(labels = ylab, limits = ylims) + 
      labs(x = NULL, y = NULL, title = paste('Cluster', i, sep = ' ')) +
      scale_x_sqrt(limits = xlims)
    
    
    plots[[i]] <- cap_plot
  }
  
  ggplot_df <- as_tibble(t(as.matrix(cluster_cap[[i]]))) %>% mutate(low_bound = 0:104) %>% 
    gather(-low_bound, key = TR_SP, value = CAP)
  
  cap_plot <- ggplot_df %>% ggplot(aes(x = low_bound, y = CAP, fill = TR_SP)) +
    geom_col() + 
    ylim(0, 75000) +
    theme_gray() + 
    theme(legend.title = element_text(size = 30), legend.text = element_text(size = 25)) +
    labs(fill = 'Species')
  
  if (!legend) cap_plot <- cap_plot + theme(legend.position = 'none')
  
  cap_legend <- ggpubr::as_ggplot(ggpubr::get_legend(cap_plot))
  
  plots[[length(cap) + 1]] <- cap_legend
  
  if (mplot) {
    multiplot(plotlist = plots, cols = plot_col, layout = layout)
  }
  if (!mplot) return(plots)
}
layout = matrix(c(1,2,3,4,5,6,7,11,8,9,10,11), nrow = 3, byrow = T)

# This function takes exactly the inputs from make_clusters and will return a 
# dataframe with summary stats for each cluster.  These include number of species,
# number of unique species, the exact unique species, number of plots, and mean, 
# var, and standard deviation of tree diameter and basal area.
summary_stats <- function(k, clusters = cluster_h_d2,
                          tot_df = df, label_df = labels, type_filter = NA,
                          species_abund = most_abund_species, filter = T,
                          filt_thresh = 0.01, codes = T){
  df <-  make_clusters(k = k, tot_df = tot_df, label_df = label_df, 
                       type_filter = type_filter, species_abund = species_abund,
                       filter = filter, clusters = clusters, codes = codes)

  sum_stats <- df %>% group_by(cluster) %>%
    summarize(
      n_species = n_distinct(TR_SP),
      num_plots = n_distinct(PID),
      mean_TPA = mean(TreesPerAcre),
      var_TPA = var(TreesPerAcre),
      sd_TPA = sd(TreesPerAcre),
      mean_DIA = mean(TR_DIA),
      var_DIA = var(TR_DIA),
      sd_DIA = sd(TR_DIA)
              )

  unique_sp <- df %>% group_by(cluster, TR_SP) %>%
    summarize(x = NA) %>%
    ungroup() %>% 
    count(TR_SP) %>%
    filter(n == 1) %>%
    .$TR_SP %>% 
    unique()

  num_unique_sp <- c()
  unique_sp_codes <- c()

  for (i in 1:k){

    . <- df %>% filter(cluster == i) %>%
      .$TR_SP %>% 
      unique()
    clust_i_unique <- .[. %in% unique_sp]

    num_unique_sp[i] <- length(clust_i_unique)

    if (length(clust_i_unique) == 0) unique_sp_codes[i] <- 'none'
    else unique_sp_codes[i] <- paste(clust_i_unique, collapse = ', ')

  }

  sum_stats <- left_join(tibble(cluster = 1:k, num_unique = num_unique_sp,
                                unique_sp = unique_sp_codes),
                         sum_stats, by = 'cluster')

  sum_stats <- sum_stats %>% select(n_species, num_unique, unique_sp,
                                    num_plots:sd_DIA)
  
  return(sum_stats)
}




