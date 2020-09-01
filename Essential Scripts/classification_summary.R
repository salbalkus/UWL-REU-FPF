#THis is the main script to generate the level 2 class CAP plots
#This script creates the level 2 classes and uses predefined functions authored by Noah to generate the CAP plots.
#Other plots to provide summary statistics are included in the end as well.
#Summary statistics are also recorded in a data file at the end after preprocessing.

library(tidyverse)
library(ggsci)
library(grid)
library(gridExtra)

path_of_code <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(path_of_code)
setwd("..")

source("classification_procedure_cluster.R")



#Functions to generate CAP plots
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
      gather(-low_bound, key = TR_SP, value = CAP) %>%
      arrange(desc(CAP))
    totals <- ggplot_df %>% group_by(TR_SP) %>% summarize(q = sum(CAP)) %>% top_n(4, q)
    ggplot_df <- filter(ggplot_df, TR_SP %in% unique(totals$TR_SP))
    
    cap_plot <- ggplot_df %>% ggplot(aes(x = low_bound, y = CAP)) +
      geom_step(aes(color = reorder(TR_SP, desc(CAP))), direction = 'hv') + 
      xlim(x_lim) + 
      theme_light() +
      theme(legend.position = 'none', axis.ticks.y = element_blank(),
            plot.title = element_text(size = 12)) +
      scale_y_continuous(labels = ylab, limits = ylims) + 
      scale_color_jco() + 
      labs(x = "DBH (inches)", y = "Abundance (TPA)", title = paste('Cluster', i, sep = ' '))
    
    
    plots[[i]] <- cap_plot
  }
  
  ggplot_df <- as_tibble(t(as.matrix(cluster_cap[[i]]))) %>% mutate(low_bound = 0:104) %>% 
    gather(-low_bound, key = TR_SP, value = CAP) %>%
    arrange(desc(CAP))
  
  totals <- ggplot_df %>% group_by(TR_SP) %>% summarize(q = sum(CAP)) %>% top_n(4, q)
  ggplot_df <- filter(ggplot_df, TR_SP %in% unique(totals$TR_SP))

  cap_plot <- ggplot_df %>% ggplot(aes(x = low_bound, y = CAP, fill = reorder(TR_SP, desc(CAP)))) +
    geom_col() + 
    scale_fill_jco() +
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

#Read in original data and level 1 classifications
df <- read_csv("clean_data/UMRS_FPF_clean.csv")
labels <- read_csv("clean_data/plot_classification.csv")
df <- left_join(df, labels, by = "PID")
df_cols_total <- df %>% filter(Label != "Mixed") %>% filter(Type %in% (df %>% group_by(Type) %>% summarize(Count = n_distinct(PID)) %>% filter(Count > 10))$Type)

#CAP FUNCTIONS: This section plots the CAP functions for each level 2 class
k = 10
DIA_bins <- 1:106

for(species in unique(df_cols_total$Type)){

labels <- read_csv("clean_data/classified_plots_labels_with_mixed.csv") %>% select(PID, cluster)
df <- left_join(load_data(species), labels, by = "PID")


cluster_cap <- df %>% stratifyvegdata(sizes1 = DIA_bins, plotColumn = 'cluster', speciesColumn = 'TR_SP', 
                                      abundanceColumn = 'TreesPerAcre', size1Column = 'TR_DIA',
                                      cumulative = T)

plots <- plot_CAP(cluster_cap, mplot = F)
grd <- grid.arrange(grid.arrange(grobs = plots[1:(length(plots)-1)]), plots[[length(plots)]], ncol = 2, widths = c(70,30))
ggsave(paste("caps/", species, ".png", sep = ""), grd)
}

#FURTHER PLOTS: This section provides clean data and a number of potential plots of summary statistics for level 2 classes.

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

table(type_counts$clusters)

#Number of level 1 classes for each potential clustering solution
ggplot(type_counts) + geom_histogram(aes(x = as.factor(clusters)), fill = "darkgreen", stat = "count") + 
  theme_light() + labs(x = "Number of Clusters", y = "Number of Level 1 Classification Types") + 
  theme(text = element_text(size = 16), legend.position = "none", axis.title.y = element_text(margin = margin(r = 10)))

#Histogram of level 2 classification types with the number of species present in the type
ggplot(plots) + geom_histogram(aes(x = Num_Species), binwidth = 1) +
  scale_fill_jco() + theme_light() + labs(x = "Number of Species Present", y = "Number of Level 2 Classification Types") + 
  theme(text = element_text(size = 16), legend.position = "none", axis.title.y = element_text(margin = margin(r = 10)))

plots_lab <- distinct(left_join(plots, select(labels, Type, Label), by = "Type"))
nrow(filter(plots_lab, Label == "Dominant"))
nrow(filter(plots_lab, Label == "Codominant"))

#Clean the data for level 1 states

quick <- read_csv("clean_data/classified_plots_labels_with_mixed.csv")
quick_dom <- quick %>% filter(Label == "Dominant") %>% group_by(Type) %>% summarize(Count = n()) %>% mutate(Pct = Count / sum(Count)) %>% top_n(5, Count)
quick_codom <- quick %>% filter(Label == "Codominant") %>% group_by(Type) %>% summarize(Count = n()) %>% mutate(Pct = Count / sum(Count)) %>%  top_n(5, Count)
quick_total <- quick %>% group_by(Type) %>% summarize(Count = n()) %>% top_n(5, Count)

#Top dominant level 1 classes
ggplot(quick_dom) + geom_col(aes(x = reorder(Type, desc(Pct)), y = Pct), fill = "#0073C2FF") + 
  theme_light() + labs(x = "Level 1 Classification", y = "Proportion of Dominant Plots") + 
  theme(text = element_text(size = 18), legend.position = "none", axis.title.y = element_text(margin = margin(r = 10)), axis.title.x = element_text(margin = margin(t = 10))) +
  scale_x_discrete(breaks=c("ACSA2","SALIX","PODE3","FRPE","SNAG"),
                   labels=c("Silver Maple","Willow","Cottonwood","Green Ash","Snag"))

#Top codominant level 1 classes
ggplot(quick_codom) + geom_col(aes(x = reorder(Type, desc(Pct)), y = Pct), fill = "#EFC000FF") + 
  scale_fill_jco() + theme_light() + labs(x = "Level 1 Classification", y = "Proportion of Codominant Plots") + 
  theme(text = element_text(size = 18), legend.position = "none", axis.title.y = element_text(margin = margin(r = 10)), axis.title.x = element_text(margin = margin(t = 20)), axis.text.x = element_text(angle = -25)) +
  scale_x_discrete(breaks=c("ACSA2 and PODE3","ACSA2 and FRPE","ACSA2 and SNAG","ACSA2 and ULAM", "ACSA2 and SALIX"),
                   labels=c("Silver Maple and\nCottonwood","Silver Maple and\nGreen Ash", "Silver Maple\nand Snag","Silver Maple and\nAmerican Elm", "Silver Maple and Willow"))

#Top level 1 classes for codominant and dominant
ggplot(quick_total) + geom_col(aes(x = reorder(Type, desc(Count)), y = Count, fill = Type)) + 
  scale_fill_jco() + theme_light() + labs(x = "Level 1 Classification", y = "Number of Plots") + 
  theme(text = element_text(size = 18), legend.position = "none", axis.title.y = element_text(margin = margin(r = 10)), axis.title.x = element_text(margin = margin(t = 20)), axis.text.x = element_text(angle = -25)) +
  scale_x_discrete(breaks=c("ACSA2","ACSA2 and PODE3","ACSA2 and FRPE","ACSA2 and SNAG","ACSA2 and ULAM"),
                   labels=c("Silver Maple", "Silver Maple and\nCottonwood","Silver Maple and\nGreen Ash", "Silver Maple\nand Snag","Silver Maple and\nAmerican Elm"))


names <- read_csv("clean_data/names.csv")
quick_new <- left_join(quick, names, by = c("Type" = "Level1", "cluster" = "cluster"))
quick_mixed_new <- quick_new %>% filter(Label == "Mixed") %>% group_by(Name) %>% summarize(Count = n() / nrow(quick_new)) %>% arrange(desc(Count))  %>% top_n(5, Count)
quick_dom_new <- quick_new %>% filter(Label == "Dominant") %>% group_by(Name) %>% summarize(Count = n() / nrow(quick_new)) %>% arrange(desc(Count))  %>% top_n(5, Count)
quick_codom_new <- quick_new %>% filter(Label == "Codominant") %>% group_by(Name) %>% summarize(Count = n() / nrow(quick_new)) %>% arrange(desc(Count))  %>% top_n(5, Count)

#Top mixed level 2 classes
ggplot(quick_mixed_new) + geom_col(aes(x = reorder(Name, desc(Count)), y = Count), fill = "#868686FF") + 
  theme_light() + labs(x = "Level 2 Classification", y = "Percentage of Plots") + 
  theme(text = element_text(size = 18), legend.position = "none", axis.title.y = element_text(margin = margin(r = 10)), axis.title.x = element_text(margin = margin(t = 20)), axis.text.x = element_text(angle = -20)) +
  scale_x_discrete(breaks=c("Complex Mixed","Multistrata Mixed with primary ACSA2"),
                   labels=c("Complex Mixed","Multistrata Mixed with\nprimary Silver Maple"))

#Top dominant level 2 classes
ggplot(quick_dom_new) + geom_col(aes(x = reorder(Name, desc(Count)), y = Count), fill = "#0073C2FF") + 
  theme_light() + labs(x = "Level 2 Classification", y = "Percentage of Plots") + 
  theme(text = element_text(size = 18), legend.position = "none", axis.title.y = element_text(margin = margin(r = 10)), axis.title.x = element_text(margin = margin(t = 20)), axis.text.x = element_text(angle = -15)) +
  scale_x_discrete(breaks=c("Complex ACSA2 with SNAG","Reinitiation SALIX","Complex PODE3","Multistrata FRPE","Multistrata SNAG"),
                   labels=c("Complex Silver Maple\nwith Snag","Reinitiation Willow","Complex Cottonwood","Multistrata Green Ash","Multistrata Snag"))

#Top codominant level 2 classes
ggplot(quick_codom_new) + geom_col(aes(x = reorder(Name, desc(Count)), y = Count), fill = "#EFC000FF") + 
  theme_light() + labs(x = "Level 2 Classification", y = "Percentage of Plots") + 
  theme(text = element_text(size = 18), legend.position = "none", axis.title.y = element_text(margin = margin(r = 10)), axis.title.x = element_text(margin = margin(t = 20)), axis.text.x = element_text(angle = -15)) +
  scale_x_discrete(breaks=c("Complex ACSA2 and PODE3","Multistrata FRPE and ACSA2","Multistrata ACSA2 and ULAM","Multistrata SNAG and ACSA2","Multistrata ACSA2 and PODE3"),
                   labels=c("Complex Silver Maple\nand Cottonwood","Multistrata Green Ash\nand Silver Maple","Multistrata Silver Maple\nand American Elm","Multistrata Snag and\nSilver Maple","Multistrata Silver Maple\nand Cottonwood"))

quick_codom_new


#Write the plot summary statistics
write_csv(plots, "plot_summary_statistics.csv")

#Create plots for the 5 USDA structural stages
names <- read_csv("clean_data/names_expanded.csv")
structures <- c("Initiation","Exclusionary","Reinitiation","Multistrata", "Complex")
counts <- c(sum(str_count(names$Name, "Initiation")),
            sum(str_count(names$Name, "Exclusionary")),
            sum(str_count(names$Name, "Reinitiation")),
            sum(str_count(names$Name, "Multistrata")),
            sum(str_count(names$Name, "Complex")))

df <- data.frame(Class = structures, Count = counts)
ggplot(df) + geom_col(aes(x = factor(Class, levels = structures), y = Count, fill = factor(Class, levels = structures))) + 
  scale_fill_jco() + labs(x = "Class") + theme_light() + 
  theme(axis.text=element_text(size=14), axis.title=element_text(size=16), legend.position = "none")

#Top 5 types by plots
quick <- read_csv("clean_data/classified_plots_labels.csv")
plotnames <- left_join(quick, names, by = c("Type" = "Level1","cluster" = "cluster"))
counts <- plotnames %>% group_by(Name) %>% summarize(Count = n())
write_csv(counts, "level2_plot_counts.csv")
counts <- top_n(5, counts)
ggplot(counts) + geom_col(aes(x = Name, y = Count))
