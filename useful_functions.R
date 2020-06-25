library(tidyverse)

df <- read_csv("clean_data/UMRS_FPF_clean.csv")
labels <- read_csv("clean_data/plot_classification.csv")
df_cols <- left_join(df, labels, by = "PID") %>% select(PID, TR_SP, TR_DIA, BasalArea, TreesPerAcre, Label)
mixed <- df_cols %>% filter(Label == 'Mixed')
load('cluster_h_d2.RData')
source('Species_dictionary.R')

plot_freq <- df %>%
  group_by(PID, TR_SP) %>%
  summarize(Freq = n()) %>%
  spread(TR_SP, Freq) %>%
  replace(is.na(.), 0)

plot_BA <- df %>%
  group_by(PID, TR_SP) %>%
  summarize(BA = sum(BasalArea)) %>%
  spread(TR_SP, BA) %>%
  replace(is.na(.), 0)

plot_rel_BA<- df %>%
  group_by(PID, TR_SP) %>%
  summarize(BA = sum(BasalArea)) %>%
  group_by(PID) %>%
  mutate(rel_BA = BA / sum(BA)) %>%
  select(-BA) %>%
  spread(TR_SP, rel_BA) %>%
  replace(is.na(.), 0)

plot_TPA <- df %>%
  group_by(PID, TR_SP) %>%
  summarize(TPA = sum(TreesPerAcre)) %>%
  spread(TR_SP, TPA) %>%
  replace(is.na(.), 0)

plot_rel_TPA <- df %>%
  group_by(PID, TR_SP) %>%
  summarize(TPA = sum(TreesPerAcre)) %>%
  group_by(PID) %>%
  mutate(rel_TPA = TPA / sum(TPA)) %>%
  select(-TPA) %>%
  spread(TR_SP, rel_TPA) %>%
  replace(is.na(.), 0)

plots <- inner_join(plot_BA, plot_rel_BA, by = c("PID"), suffix = c("_BA","_rel_BA"))
plots <- inner_join(plot_freq, plots, by = c("PID"))

plots_tpa <- inner_join(plot_TPA, plot_rel_TPA, by = c("PID"), suffix = c("_TPA","_rel_TPA"))
plots <- inner_join(plots_tpa, plots, by = c("PID"))

most_abund_species <- mixed %>% count(TR_SP) %>% filter(n/sum(n) >= 0.01) %>% .$TR_SP 



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

plot_CAP <- function(cap, x_lim = c(0, 40), mplot = T, plot_col = 4, layout = NULL,
                     ylab = waiver(), ylims = NULL){
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
      scale_y_continuous(labels = ylab, limits = ylims) + 
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
