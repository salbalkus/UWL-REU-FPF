library(tidyverse)
library(vegclust)
library(cluster)
library(rpart)
library(rpart.plot)
library(zoo)
library(vegan)
library(infotheo)

path_of_code <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(path_of_code)

dissim <- read_csv("dissimilarity_matrix.csv")
dissim <- as.matrix(dissim)

cluster_h <- hclust(as.dist(dissim), method = "ward.D2")
plots <- left_join(read_csv("clean_data/plots.csv"), read_csv("clean_data/plot_classification.csv"), by = "PID")
plots_acsa2 <- plots %>% filter(Type == "ACSA2")
form <- paste( "cluster ~", paste0(colnames(plots_acsa2)[2:(ncol(plots_acsa2)-2)], collapse = " + "))

### Using comparisons between tree and hierarchical clustering ###
cut <- cutree(cluster_h, k = 10)
plots_acsa2$cluster <- cut
tree <- rpart(data = plots_acsa2, formula = form, method = "class", control = rpart.control(maxdepth = ceiling(log(2*10,2)), cp = 0, minbucket = 6))

#Homogeneity and Completeness
# here we assume the Ward clustering to be the "true classes"
plots_acsa2$tree <- predict(tree, plots_acsa2, type = "vector")
conf <- table(as.factor(plots_acsa2$cluster), factor(plots_acsa2$tree, levels = seq(1:10)))

h <- 1 - condentropy(plots_acsa2$cluster, plots_acsa2$tree) / entropy(plots_acsa2$cluster)
c <- 1 - condentropy(plots_acsa2$tree, plots_acsa2$cluster) / entropy(plots_acsa2$tree)

#Validity measure - combines homogeneity and completeness

validity <- 2 * ((h*c) / (h + c))

#Now we compare across multiple clusters
max_clusters <- 100
vmeasures <- vector(length = max_clusters - 1)
for(n in 2:max_clusters){
  cut <- cutree(cluster_h, k = n)
  plots_acsa2$cluster <- cut
  
  tree <- rpart(data = plots_acsa2, formula = form, method = "class", control = rpart.control(maxdepth = ceiling(log(2*n,2)), cp = 0, minbucket = 1))
  plots_acsa2$tree <- predict(tree, plots_acsa2, type = "vector")
  
  h <- 1 - condentropy(plots_acsa2$cluster, plots_acsa2$tree) / entropy(plots_acsa2$cluster)
  c <- 1 - condentropy(plots_acsa2$tree, plots_acsa2$cluster) / entropy(plots_acsa2$tree)
  
  vmeasures[n-1] <- 2 * ((h*c) / (h + c))
}

#higher validity measures are better
plot((seq(1:99) + 1),vmeasures)

best_k <- which.max(vmeasures) + 1
best_k

#Hence, we find that for silver maples, cutting the Ward cluster at k = 5 is the best choice for validity (with max clusters equal to 20)
#With max clusters at 100, the best choice is 94, which is obviously far too many

