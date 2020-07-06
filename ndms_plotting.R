library(tidyverse)
library(ggsci)

path_of_code <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(path_of_code)

labels <- read_csv("clean_data/classified_plots_labels.csv")
coords <- read_csv("clean_data/SALIX.full.df.csv")
nmds <- left_join(nmds, labels, by = "PID")

nmds

ggplot(nmds) + geom_point(aes(x = MDS1, y = MDS2, color = as.factor(cluster))) + scale_color_jco() + theme_light()
