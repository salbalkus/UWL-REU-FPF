library(tidyverse)
library(ggsci)
library(grid)
library(gridExtra)
source("classification_procedure_cluster.R")

path_of_code <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(path_of_code)

multiplot <- function(..., plotlist=NULL, file, cols=1, layout=NULL) {

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
plot_CAP <- function(cap, x_lim = c(0, 40), mplot = T, plot_col = 3, layout = NULL,
                     ylab = waiver(), ylims = NULL){
  plots <- list()
  for (i in 1:length(cap)){
    ggplot_df <- as_tibble(t(as.matrix(cluster_cap[[i]]))) %>% mutate(low_bound = 0:104) %>% 
      gather(-low_bound, key = TR_SP, value = CAP)
    
    cap_plot <- ggplot_df %>% ggplot(aes(x = low_bound, y = CAP)) +
      geom_step(aes(color = TR_SP), direction = 'hv') + 
      xlim(x_lim) + 
      theme_light() +
      theme(legend.position = 'none', axis.ticks.y = element_blank(),
            plot.title = element_text(size = 12)) +
      scale_y_continuous(labels = ylab, limits = ylims) + 
      labs(x = "Size (BA)", y = "Abundance (TPA)", title = paste('Cluster', i, sep = ' '))
    
    
    plots[[i]] <- cap_plot
  }
  
  ggplot_df <- as_tibble(t(as.matrix(cluster_cap[[i]]))) %>% mutate(low_bound = 0:104) %>% 
    gather(-low_bound, key = TR_SP, value = CAP)
  
  cap_plot <- ggplot_df %>% ggplot(aes(x = low_bound, y = CAP, fill = TR_SP)) +
    geom_col() + 
    ylim(0, 75000) +
    theme_light() + 
    theme(legend.title = element_text(size = 12), legend.text = element_text(size = 12)) +
    labs(fill = 'Species')
  
  cap_legend <- ggpubr::as_ggplot(ggpubr::get_legend(cap_plot))
  
  plots[[length(cap) + 1]] <- cap_legend
  
  if (mplot) {
    multiplot(plotlist = plots, cols = plot_col, layout = layout)
  }
  if (!mplot) return(plots)
}

df <- read_csv("clean_data/UMRS_FPF_clean.csv")
labels <- read_csv("clean_data/plot_classification.csv")
df <- left_join(df, labels, by = "PID")
df_cols_total <- df %>% filter(Label != "Mixed") %>% filter(Type %in% (df %>% group_by(Type) %>% summarize(Count = n_distinct(PID)) %>% filter(Count > 10))$Type)

k = 10
DIA_bins <- 1:106

for(species in unique(df_cols_total$Type)){

labels <- read_csv("clean_data/classified_plots_labels.csv") %>% select(PID, cluster)
df <- left_join(load_data(species), labels, by = "PID")


cluster_cap <- df %>% stratifyvegdata(sizes1 = DIA_bins, plotColumn = 'cluster', speciesColumn = 'TR_SP', 
                                      abundanceColumn = 'TreesPerAcre', size1Column = 'TR_DIA',
                                      cumulative = T)

plots <- plot_CAP(cluster_cap, mplot = F)
grd <- grid.arrange(grid.arrange(grobs = plots[1:(length(plots)-1)]), plots[[length(plots)]], ncol = 2, widths = c(70,30))
ggsave(paste("caps/", species, ".png", sep = ""), grd)
}


plots <- df %>% left_join(select(read_csv("clean_data/classified_plots_labels.csv"), PID, cluster)) %>% group_by(Type, cluster) %>%
  summarize(Total_TPA = sum(TreesPerAcre),
            q25_TPA = quantile(TreesPerAcre, probs = 0.25),
            Median_TPA = median(TreesPerAcre),
            q75_TPA = quantile(TreesPerAcre, probs = 0.75),
            Total_BA = sum(BasalArea),
            q25_BA = quantile(BasalArea, probs = 0.25),
            Median_BA = median(BasalArea),
            q75_BA = quantile(BasalArea, probs = 0.75),
            Num_Species = n_distinct(TR_SP)
            ) %>%
  filter(!is.na(cluster))

plots <- read_csv("clean_data/plot_summary_statistics.csv")
plots
type_counts <- plots %>% group_by(Type) %>% summarize(clusters = max(cluster))


ggplot(type_counts) + geom_histogram(aes(x = as.factor(clusters), fill = as.factor(clusters)), stat = "count") +
  scale_fill_jco() + theme_light() + labs(x = "Number of Clusters", y = "Number of Level 1 Classification Types") + 
  theme(text = element_text(size = 16), legend.position = "none", axis.title.y = element_text(margin = margin(r = 10)))

ggplot(plots) + geom_histogram(aes(x = Num_Species), binwidth = 1) +
  scale_fill_jco() + theme_light() + labs(x = "Number of Species Present", y = "Number of Level 2 Classification Types") + 
  theme(text = element_text(size = 16), legend.position = "none", axis.title.y = element_text(margin = margin(r = 10)))

plots_lab <- distinct(left_join(plots, select(labels, Type, Label), by = "Type"))
nrow(filter(plots_lab, Label == "Dominant"))
nrow(filter(plots_lab, Label == "Codominant"))

quick <- read_csv("clean_data/classified_plots_labels.csv")
quick_dom <- quick %>% filter(Label == "Dominant") %>% group_by(Type) %>% summarize(Count = n()) %>% top_n(5, Count)
quick_codom <- quick %>% filter(Label == "Codominant") %>% group_by(Type) %>% summarize(Count = n()) %>% top_n(5, Count)

ggplot(quick_dom) + geom_col(aes(x = reorder(Type, desc(Count)), y = Count, fill = Type)) + 
  scale_fill_jco() + theme_light() + labs(x = "Level 1 Classification", y = "Number of Plots") + 
  theme(text = element_text(size = 16), legend.position = "none", axis.title.y = element_text(margin = margin(r = 10)), axis.title.x = element_text(margin = margin(t = 10)))

ggplot(quick_codom) + geom_col(aes(x = reorder(Type, desc(Count)), y = Count, fill = Type)) + 
  scale_fill_jco() + theme_light() + labs(x = "Level 1 Classification", y = "Number of Plots") + 
  theme(text = element_text(size = 16), legend.position = "none", axis.title.y = element_text(margin = margin(r = 10)), axis.title.x = element_text(margin = margin(t = 20)), axis.text.x = element_text(angle = -20))


write_csv(plots, "plot_summary_statistics.csv")


