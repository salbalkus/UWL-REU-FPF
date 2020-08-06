library(tidyverse)
library(ggsci)

path_of_code <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(path_of_code)

labels <- read_csv("clean_data/classified_plots_labels.csv")
coords <- read_csv("clean_data/SALIX.full.df.csv")
nmds <- left_join(coords, labels, by = "PID")

nmds