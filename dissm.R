library(tidyverse)
library(kernlab)
library(dbscan)
library(vegclust)
library(cluster)
library(ggsci)

path_of_code <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(path_of_code)

#Read in the code and start by analyzing ACSA2. The process used here can be applied automatically to the other species later on. 

df <- read_csv("clean_data/UMRS_FPF_clean.csv")
labels <- read_csv("clean_data/plot_classification.csv")
df_cols <- left_join(df, labels, by = "PID") %>% select(PID, TR_SP, BasalArea, TreesPerAcre, Type, Label)
df_acsa2 <- filter(df_cols, Type == "ACSA2")
#Only 28 species to deal with in the silver maple dominant communities!
length(unique(df_acsa2$TR_SP))

#TPA = 1 / (pi * (DBH*2.75)^2) / 43560)
#BA = 0.25*pi*(DBH^2)
TPA_bins = 1 / (pi * (seq(1:106)*2.75)^2) / 43560
BA_bins = 0.25*pi*(seq(1:106)^2)


#confirm TPA length
(1/sqrt(TPA_bins))[2] - (1/sqrt(TPA_bins))[1]
(1/sqrt(TPA_bins))[3] - (1/sqrt(TPA_bins))[2]


#Confirm uniform distribution
qplot(1/sqrt(TPA_bins), binwidth = 1017.306)
qplot(sqrt(BA_bins), binwidth = sqrt(BA_bins)[2] - sqrt(BA_bins)[1])


#Stratify the vegetation data
test <- stratifyvegdata(df_acsa2, sizes1 = BA_bins, plotColumn = "PID", speciesColumn = "TR_SP", abundanceColumn = "TreesPerAcre", size1Column = "BasalArea", cumulative = TRUE )
cap <- CAP(test)

#Plot for individual species in one plot as in De Caceres, 2013. Probably do not want to use
ggplot(filter(df_acsa2, PID == "Cuivre-1-41")) + geom_step(aes(x = BasalArea, y = TreesPerAcre, color = TR_SP )) + theme_light()

#Compare CAP for multiple plots
example <- cap[[1]][rowSums(cap[[1]][,-1]) > 0,colSums(cap[[1]][-1,]) > 0]
example

plot(cap, plots = "1", sizes = BA_bins[1:5])

dissim <- vegdiststruct(cap, method = "manhattan")
write_csv(as.data.frame(as.matrix(dissim)), "dissimilarity_matrix.csv")