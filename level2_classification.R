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

#It appears that the data must be stratified. How should the data be stratified?

test <- stratifyvegdata(df_acsa2, plotColumn = "PID", speciesColumn = "TR_SP", abundanceColumn = "TreesPerAcre", size1Column = "BasalArea" )

kmeans(df_acsa2$TreesPerAcre, centers = n)
