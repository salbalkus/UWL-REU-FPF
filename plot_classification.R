library(tidyverse)
library(kernlab)
library(dbscan)

df <- read_csv("clean_data/UMRS_FPF_clean.csv")

plot_abundance <- df %>%
  group_by(PID, TR_SP) %>%
  summarize(TPA = sum(TreesPerAcre)) %>%
  group_by(PID) %>%
  mutate(relTPA = TPA / sum(TPA)) %>%
  select(-TPA) %>%
  #spread(TR_SP, Density) %>%
  replace(is.na(.), 0)

plot_size <- df %>%
  group_by(PID, TR_SP) %>%
  summarize(BasalArea = sum(BasalArea)) %>%
  group_by(PID) %>%
  mutate(relBA = BasalArea / sum(BasalArea)) %>%
  select(-BasalArea) %>%
  #spread(TR_SP, PctBasalArea) %>%
  replace(is.na(.), 0)

plots <- inner_join(plot_abundance, plot_size, by = c("PID", "TR_SP"))#, suffix = c("", "_ba"))

dominant <- plots %>%
  filter(relTPA > 0.8 & relBA > 0.8)

dominant$Type <- dominant$TR_SP
dominant$Label <- "Dominant"

codominant <- plots %>%
  filter(relTPA <= 0.8 | relBA <= 0.8) %>%
  filter(relTPA >= 0.2 | relBA >= 0.2) %>%
  group_by(PID) %>%
  filter(relTPA + max(relTPA) > 0.8 & relBA + max(relBA) > 0.8) %>%
  filter(n() > 1) %>%
  filter(sum(relTPA) > 0.8 & sum(relBA) > 0.8)

#Proof that the codominant group is correct - should result in empty data frame
codominant %>% group_by(PID) %>% summarize(d = sum(relTPA), ba = sum(relBA)) %>% filter(d <= 0.8 | ba <= 0.8)
#Should also result in empty df if codominant is performed correctly
codominant %>% group_by(PID) %>% summarize(l = length(PID)) %>% filter(l != 2)

codominant <- codominant %>%
  group_by(PID) %>%
  summarize(relTPA = sum(relTPA), relBA = sum(relBA), Type = paste0(TR_SP, collapse= " and "), Label = "Codominant")

dominant <- select(dominant, PID, Type, Label)
codominant <- select(codominant, PID, Type, Label)

mixed <- df %>%
  filter(!PID %in% dominant$PID) %>%
  filter(!PID %in% codominant$PID) %>%
  select(PID) %>%
  mutate(Type = NA, Label = "Mixed") %>%
  distinct()

output <- bind_rows(dominant, codominant, mixed)
write_csv(output, "clean_data/plot_classification.csv")

plots_output <- df %>%
  group_by(PID, TR_SP) %>%
  summarize(TPA = n(), BasalArea = sum(BasalArea)) %>%
  group_by(PID) %>%
  mutate(tpa = TPA / sum(TPA), ba = BasalArea / sum(BasalArea)) %>%
  select(-TPA, -BasalArea) %>%
  pivot_wider(names_from = TR_SP, values_from = c(tpa, ba)) %>%
  replace(is.na(.), 0)

plots_output <- inner_join(output, plots_output, by = c("PID"))
write_csv(plots_output, "clean_data/plots_full.csv")

#Top types just the most common species
explore1 <- plots_output %>%
  group_by(Type) %>%
  summarize(Count = n()) %>%
  arrange(desc(Count))

explore2 <- plots_output %>%
  filter(Label == "Dominant") %>%
  group_by(Type) %>%
  summarize(Count = n()) %>%
  arrange(desc(Count))

explore3 <- plots_output %>%
  filter(Label == "Codominant") %>%
  group_by(Type) %>%
  summarize(Count = n()) %>%
  arrange(desc(Count))


#There are 36 dominant plot types and 186 codominant plot types
nrow(unique(plots_output[plots_output$Label == "Dominant","Type"]))
nrow(unique(plots_output[plots_output$Label == "Codominant","Type"]))

mixed <- filter(plots_output, Label == "Mixed")
mixed_sel <- mixed[,4:ncol(mixed)]
mixed_sel <- mixed_sel[,colSums(mixed_sel) != 0]

#test <- mixed_sel[1:600,]
#test

#cluster <- kmeans(x = mixed_sel, centers = 20)
#cluster <- specc(x = mixed_sel, centers = 3) #This one takes too long to run right now...
#cluster <- dbscan(mixed_sel, eps = 0.23)
cluster <- hclust(dist(mixed_sel, method = "euclidean"), method = "single")

#based on the dendrogram, it looks like it can be cut at a number of heights. Let's do 3.
plot(cluster)

cluster <- cutree(cluster, h = 0.2)
cluster


pc <- prcomp(mixed_sel)
pc1 <- pc$x[,1]
pc2 <- pc$x[,2]
bp <- data.frame(pc1, pc2, cluster)
ggplot(bp) + geom_point(aes(x = pc1, y = pc2, color = as.factor(cluster))) + scale_color_viridis_d()



#Show the biplot with direction vectors for attributes
biplot(pc, xlabs=rep("·", nrow(mixed_sel)))

#Proportion of variance explained for each principal component
#PC1 and PC2 only make up about 54.9% of the variance 
summary(pc)$importance[2,]
