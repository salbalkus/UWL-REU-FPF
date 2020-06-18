library(tidyverse)
library(kernlab)
library(dbscan)
library(vegclust)
library(cluster)

path_of_code <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(path_of_code)

#Read in the code and start by analyzing ACSA2. The process used here can be applied automatically to the other species later on. 

df <- read_csv("clean_data/UMRS_FPF_clean.csv")
labels <- read_csv("clean_data/plot_classification.csv")
labels
df_cols <- left_join(df, labels, by = "PID") %>% select(PID, TR_SP, BasalArea, TreesPerAcre, Type, Label)
df_acsa2 <- filter(df_cols, Type == "ACSA2")
#Only 28 species to deal with in the silver maple dominant communities!
length(unique(df_acsa2$TR_SP))

#Here we see the maximum diameter is 106 and they are measured in increments of 1
sort(df$TR_DIA, decreasing = TRUE)

#TPA = 1 / (pi * (DBH*2.75)^2) / 43560)
#BA = 0.25*pi*(DBH^2)
TPA_bins = 1 / (pi * (seq(1:106)*2.75)^2) / 43560
BA_bins = 0.25*pi*(seq(1:106)^2)


#confirm TPA length
(1/sqrt(TPA_bins))[2] - (1/sqrt(TPA_bins))[1]
(1/sqrt(TPA_bins))[3] - (1/sqrt(TPA_bins))[2]

tpa_tf < function(x){return(1/sqrt(x))}
ba_tf <- function(x){return(sqrt(x))}

#Confirm uniform distribution
qplot(1/sqrt(TPA_bins), binwidth = 1017.306)
qplot(sqrt(BA_bins), binwidth = sqrt(BA_bins)[2] - sqrt(BA_bins)[1])


#Stratify the vegetation data
test <- stratifyvegdata(df_acsa2, sizes1 = BA_bins, plotColumn = "PID", speciesColumn = "TR_SP", abundanceColumn = "TreesPerAcre", size1Column = "BasalArea" )
cap <- CAP(test)

#Plot for individual species in one plot as in De Caceres, 2013. Probably do not want to use
ggplot(filter(df_acsa2, PID == "Cuivre-1-41")) + geom_step(aes(x = BasalArea, y = TreesPerAcre, color = TR_SP )) + theme_light()

#Compare CAP for multiple plots
example <- cap[[1]][rowSums(cap[[1]][,-1]) > 0,colSums(cap[[1]][-1,]) > 0]
example
ggplot()

plot(cap, plots = "1", sizes = BA_bins[1:5])

dissim <- vegdiststruct(cap, method = "bray")
write_csv(as.data.frame(as.matrix(dissim)), "dissimilarity_matrix.csv")

###Checkpoint###
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

#Hierarchical Clustering
cluster_h <- hclust(dist(dissim), method = "ward.D")
plot(cluster_h$


#OPTICS
#Note that with minPts = 2, the algorithm is identical to hierarchical clustering. Must determine some larger
#minimum number of points within a cluster
cluster_o <- optics(as.matrix(dissim), eps = 10, minPts = 6)
cluster_db <- extractDBSCAN(cluster_o, eps_cl = 1.2)
plot(cluster_db)
sort(unique(cluster_db$cluster))

#Personally, I am dissatisfied with this approach. We should stick to hierarchical
