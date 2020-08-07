#This script provides potential tests for splitting and using the decision tree for classification.
#We did not end up using this approach.

library(tidyverse)
library(vegclust)
library(cluster)
library(rpart)
library(rpart.plot)
library(zoo)
library(vegan)

path_of_code <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(path_of_code)

#### ACCURACY TEST ####
dissim <- read_csv("dissimilarity_matrix.csv")
dissim <- as.matrix(dissim)

cluster_h <- hclust(as.dist(dissim), method = "ward.D2")
plot(cluster_h, labels = FALSE)

plots_relative <- read_csv("clean_data/plots_full.csv")
plots_acsa2 <- plots %>% filter(Type == "ACSA2")

form <- paste( "cluster ~", paste0(colnames(plots_acsa2)[2:(ncol(plots_acsa2)-2)], collapse = " + "))

results <- vector(length = 19)
for(n in 2:20){
  cut <- cutree(cluster_h, k = n)
  plots_acsa2$cluster <- cut
  
  tree <- rpart(data = plots_acsa2, formula = form, method = "class", control = rpart.control(maxdepth = ceiling(log(n*2,2)), cp = 0, minbucket = 6))
  
  result <- table(predict(tree, t="class"), plots_acsa2$cluster)
  results[n-1] <- sum(diag(result)) / sum(result)
}
plot((seq(1:19)+1),results)


results <- vector(length = 19)
for(n in 2:20){
  cut <- cutree(cluster_h, k = n)
  plots_acsa2$cluster <- cut
  
  tree <- rpart(data = plots_acsa2, formula = form, method = "class", control = rpart.control(maxdepth = ceiling(log(n*2,2)), cp = 0, minbucket = 1))
  
  result <- table(predict(tree, t="class"), plots_acsa2$cluster)
  results[n-1] <- min(na.fill(diag(result) / rowSums(result), 0))
}
plot(seq(2:20),results[2:20])

## Silhouettes for different cuts

clusters <- 20
sil <- vector("list", length = clusters-1)
for(n in 2:clusters){
  sil[[n-1]] <- silhouette(x = cutree(cluster_h, k = n), dmatrix = as.matrix(dissim))
}

plot(sil[[4]], border = NA)


avg_widths <- vector(length = clusters-1)
for(n in 2:clusters){avg_widths[n-1] <- mean(sil[[n-1]][,3])}

df <- data.frame(seq(2:20),avg_widths, colnames = c("Clusters","Average Silhouette Length"))

qplot((seq(1:19) + 1), avg_widths) + theme_light() + xlab("Clusters") + ylab("Average Silhouette Width")

which.min(avg_widths)

## Basal Area Comparisons ##
plot_acsa2$cluster <- cutree(cluster_h, k = 10)
df <- read_csv("clean_data/UMRS_FPF_clean.csv")
labs <- read_csv("clean_data/plot_classification.csv")
df <- df %>% left_join(labs, by = "PID") %>% filter(Type == "ACSA2")

clusters <- plots_acsa2 %>% select(PID, cluster)
df <- left_join(df, clusters, by = "PID")

ggplot(df) + geom_density(aes(x = TR_DIA), fill = "lightblue") + facet_wrap(~cluster)

grouped <- df %>% group_by(cluster) %>% summarize(Avg_Diam = mean(TR_DIA))
ggplot(grouped) + geom_col(aes(x = as.factor(cluster), y = Avg_Diam, fill = as.factor(cluster))) + theme_light() + xlab("Cluster") + ylab("Average Diameter") + scale_fill_viridis_d()

tree <- rpart(data = plots_acsa2, formula = form, method = "class", control = rpart.control(maxdepth = 4, cp = 0, minbucket = 6))
rpart.plot(tree)
summary(tree)
printcp(tree)
ggplot(plots_acsa2) + geom_point(aes(x = log(BA_ACSA2), y = log(TPA_ACSA2), color = as.factor(cluster))) + scale_color_jco() + theme_light()



