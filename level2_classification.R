library(tidyverse)
library(kernlab)
library(dbscan)
library(vegclust)

path_of_code <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(path_of_code)

#Read in the code and start by analyzing ACSA2. The process used here can be applied automatically to the other species later on. 

df <- read_csv("clean_data/UMRS_FPF_clean.csv")
df_ba <- select(df, PID, TR_SP, BasalArea, TreesPerAcre)
df_acsa2 <- filter(df_ba, TR_SP == "ACSA2")

#Before we start using CAP, we need to somehow stratify the size and abundance classes. 
clusters <- c(length = 50)
for(n in 1:50){
  clusters[n] <- kmeans(df_acsa2$TreesPerAcre, centers = n)$tot.withinss
}
plot(10:50, clusters[10:50])

#Here we see the maximum diameter is 106 and they are measured in increments of 1
sort(df$TR_DIA, decreasing = TRUE)

#TPA = 1 / (pi * (DBH*2.75)^2) / 43560)
#BA = 0.25*pi*(DBH^2)
TPA_bins = 1 / (pi * (seq(1:106)*2.75)^2) / 43560
BA_bins = 0.25*pi*(seq(1:106)^2)

log(1/TPA_bins)[2] - log(TPA_bins,10)[1]
log(TPA_bins,10)[3] - log(TPA_bins,10)[2]


qplot(log(TPA_bins), binwidth = TPA_bins[1] - TPA_bins[2])


qplot(sqrt(BA_bins), binwidth = sqrt(BA_bins)[2] - sqrt(BA_bins)[1])

sqrt(BA_bins)[2] - sqrt(BA_bins)[1]



test <- stratifyvegdata(df_acsa2, plotColumn = "PID", speciesColumn = "TR_SP", abundanceColumn = "TreesPerAcre", size1Column = "BasalArea" )

kmeans(df_acsa2$TreesPerAcre, centers = n)

