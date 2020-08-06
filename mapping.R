library(tidyverse)
library(sf)
library(ggsci)

path_of_code <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(path_of_code)

theme_set(theme_light())

#Fixed plots

df <- st_read("Datasets/Spatial_Data/RockIsland/Huron_Fixed_Plot_2012.shp")
labels <- read_csv("clean_data/classified_plots_labels_with_mixed.csv")
names <- read_csv("clean_data/names.csv")

labels_merge <- left_join(labels, names, by = c("Type" = "Level1","cluster" = "cluster"))

merge <- left_join(df, labels_merge, by = "PID")

df$STAND

df_test <- merge %>% filter(STAND == "s005")

df$POOL


ggplot(df_test) + geom_sf(aes(color = Type), size = 4) + labs(x = "\nEasting", y = "Northing\n", color = "Level 1 Class") + 
  theme(legend.title =  element_text(size = 18), axis.title =  element_text(size = 16), legend.text = element_text(size = 12), legend.key.width = unit(1, "cm")) +
  scale_color_viridis_d(breaks=c("ACSA2","ACSA2 and FRPE","ACSA2 and PODE3","ACSA2 and SNAG","ACSA2 and ULAM", "Mixed","PODE3 and ULAM"),
                   labels=c("Silver Maple", "Silver Maple and Green Ash","Silver Maple and Cottonwood", "Silver Maple and Snag","Siler Maple and American Elm","Mixed","Cottonwood and American Elm"))



ggplot(df_test) + geom_sf(aes(color = Name))
df_test


