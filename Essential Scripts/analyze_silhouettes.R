library(tidyverse)

path_of_code <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(path_of_code)
setwd("..")

df <- read_csv("clean_data/Level 2 Avg Silhouette.csv")

top5 <- df %>% arrange(desc(`avg_sil <- mean(sil_width)`)) %>% top_n(5)

ggplot(top5) + geom_col(aes(x = reorder(Level2, -`avg_sil <- mean(sil_width)`), y = `avg_sil <- mean(sil_width)`), width = 0.75, fill = "gray") +
  labs(x = "Level 2 Class", y = "Average Silhouette Length") +
  theme_light()
