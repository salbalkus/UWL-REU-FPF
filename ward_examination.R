library(tidyverse)
library(kernlab)
library(dbscan)
library(vegclust)
library(cluster)
library(ggsci)

path_of_code <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(path_of_code)

df <- read_csv("clean_data/UMRS_FPF_clean.csv")
labels <- read_csv("clean_data/plot_classification.csv")
df_cols <- left_join(df, labels, by = "PID") %>% select(PID, TR_SP, BasalArea, TreesPerAcre, Type, Label)
df_acsa2 <- filter(df_cols, Type == "ACSA2")

dissim <- read_csv("dissimilarity_matrix.csv")
dissim <- as.matrix(dissim)

cluster_h <- hclust(as.dist(dissim), method = "ward.D")
plot(cluster_h, labels = FALSE)

#First, we must create a new data frame with the non-relative values to explore

plot_abundance <- df %>%
  group_by(PID, TR_SP) %>%
  summarize(TPA = sum(TreesPerAcre)) %>%
  replace(is.na(.), 0) 

plot_size <- df %>%
  group_by(PID, TR_SP) %>%
  summarize(BA = sum(BasalArea)) %>%
  replace(is.na(.), 0)

plots <- inner_join(plot_abundance, plot_size, by = c("PID", "TR_SP")) %>% 
  pivot_wider(names_from = TR_SP, values_from = c(TPA, BA)) %>% 
  replace(is.na(.), 0)

plots <- left_join(plots, labels, by = "PID")
write_csv(plots, "plots_nonrel.csv")

plots_relative <- read_csv("clean_data/plots_full.csv")


plots_acsa2 <- plots %>% filter(Type == "ACSA2")


result <- cutree(cluster_h, k = 5)
plots_acsa2$cluster <- result

#Voila! The sort of result we've been looking for
ggplot(plots_acsa2) + geom_point(aes(x = sqrt(BA_ACSA2), y = TPA_ACSA2, color = as.factor(cluster))) + scale_color_jco() + theme_light()

pc <- prcomp(plots_acsa2[,2:(ncol(plots_acsa2)-3)])
pc1 <- pc$x[,1]
pc2 <- pc$x[,2]
cluster <- plots_acsa2$cluster
bp <- data.frame(pc1, pc2, cluster)
ggplot(bp) + geom_point(aes(x = pc1, y = pc2, color = as.factor(cluster))) + scale_color_jco() + theme_light()


#Show the biplot with direction vectors for attributes
biplot(pc, xlabs=rep("·", nrow(bp)))

#Proportion of variance explained for each principal component
#PC1 and PC2 only make up about 54.9% of the variance 
summary(pc)$importance[2,]

