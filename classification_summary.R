library(tidyverse)
library(ggsci)
source("classification_procedure_cluster.R")

path_of_code <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(path_of_code)

labels <- read_csv("clean_data/classified_plots_labels.csv") %>% select(PID, cluster)
df <- load_data("ACNE2")
dissim <- dissimilarity_matrix(df)


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
    theme(legend.title = element_text(size = 30), legend.text = element_text(size = 25)) +
    labs(fill = 'Species')
  
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

scale_y_

