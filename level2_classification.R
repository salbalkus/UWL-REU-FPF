library(tidyverse)
library(kernlab)
library(dbscan)
library(vegclust)
library(cluster)
library(ggsci)

path_of_code <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(path_of_code)

dissim <- read_csv("dissimilarity_matrix.csv")
dissim <- as.matrix(dissim)

summary(as.vector(dissim)) #appears to be relatively normal
qplot(as.vector(dissim), geom = "boxplot")

#Evaluate different numbers of clusters for kmeans
clusters <- 20
cluster_k <- vector("list", length = clusters)
for(n in 1:clusters) {
  cluster_k[[n]] <- kmeans(dissim, n)
}
#Elbow method
cluster_k_twss <- vector(length = clusters)
for(n in 1:clusters){
  cluster_k_twss[n] <- cluster_k[[n]]$tot.withinss
}
plot(cluster_k_twss)



#Silhouette
sil <- vector("list", length = clusters)
for(n in 1:clusters){
  sil[[n]] <- silhouette(x = cluster_k[[n]]$cluster, dmatrix = as.matrix(dissim))
}
plot(sil[[2]], col = 1:2, border = NA)

#Plot average sil length
avg_sil_len <- vector(length = clusters-1)
min_sil_len <- vector(length = clusters-1)
avg_sil_neg <- vector(length = clusters-1)
for(n in 2:clusters){avg_sil_len[n-1] <- mean(sil[[n]][,3])}
for(n in 2:clusters){min_sil_len[n-1] <- min(sil[[n]][,3])}
for(n in 2:clusters){avg_sil_neg[n-1] <- mean(sil[[n]][sil[[n]][,3] < 0,3])}

plot(avg_sil_len)
plot(min_sil_len)
plot(avg_sil_neg) #minimum is at 13 clusters

#Plot regularized average silhouette
plot(avg_sil_len*(1+ 0.1*seq(2:clusters)))



#Gap statistics
gap <- clusGap(as.matrix(dissim), kmeans, K.max = 20, B = 10, d.power = 2, verbose = TRUE)
write_csv(as.data.frame(gap[[1]]), "gap_kmeans.csv")
plot(as.matrix(gap[[1]])[,3])


#OPTICS
#Note that with minPts = 2, the algorithm is identical to hierarchical clustering. Must determine some larger
#minimum number of points within a cluster
cluster_o <- optics(as.matrix(dissim), eps = 10, minPts = 6)
cluster_db <- extractDBSCAN(cluster_o, eps_cl = 1.2)
plot(cluster_db)
sort(unique(cluster_db$cluster))

#Personally, I am dissatisfied with this approach. We should stick to hierarchical

heatmap(dissim[1:100,1:100])
qplot(as.vector(dissim))


#Hierarchical Clustering

cluster_h <- hclust(as.dist(dissim), method = "average")
plot(cluster_h, labels = FALSE)

cluster_h <- hclust(as.dist(dissim), method = "ward.D")
plot(cluster_h)





