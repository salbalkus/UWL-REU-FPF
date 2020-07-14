library(tidyverse)
library(sf)

path_of_code <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(path_of_code)

theme_set(theme_light())

#Fixed plots

df <- st_read("Datasets/Spatial_Data/RockIsland/Huron_Fixed_Plot_2012.shp")
labels <- read_csv("clean_data/classified_plots_labels_with_mixed.csv")
names <- read_csv("caps/names.csv")


merge <- left_join(df, labels, by = "PID")

merge

df_test <- merge %>% filter(POOL == "p18")
df_test
#ch <- df_test %>% group_by(PID) %>% summarize(geometry = st_convex_hull(st_union(geometry)))

ggplot(df_test) + geom_sf(aes(color = Label))
ggplot(df_test) + geom_sf(aes(color = Type))



df_test


