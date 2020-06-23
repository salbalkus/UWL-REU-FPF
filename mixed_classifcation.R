# Clustering algorithm for mixed plots

library(tidyverse)
library(vegclust)
library(lubridate)
library(RFLPtools)

path_of_code <- rprojroot::find_rstudio_root_file()

df <- read_csv("clean_data/UMRS_FPF_clean.csv")
labels <- read_csv("clean_data/plot_classification.csv")

df_cols <- left_join(df, labels, by = "PID") %>% select(PID, TR_SP, TR_DIA, BasalArea, TreesPerAcre, Label)

mixed <- df_cols %>% filter(Label == 'Mixed')

# Number of unique PIDs in mixed category
n_distinct(mixed$PID)

# Bins for CAP
TPA_bins <- 1 / (pi * (seq(1:106)*2.75)^2) / 43560
BA_bins <- 0.25*pi*(seq(1:106)^2)
DIA_bins <- 1:106

test <- mixed %>% stratifyvegdata(sizes1 = DIA_bins, plotColumn = 'PID', speciesColumn = 'TR_SP', 
                                  abundanceColumn = 'TreesPerAcre', size1Column = 'TR_DIA',
                                  cumulative = T)

cap <- CAP(test)

sort(unique(mixed$PID))

start <- now()
dissim <- vegdiststruct(cap, method = 'manhattan')
end <- now()
print(end - start)


write_csv(as.data.frame(as.matrix(dissim)), 'mixed_dissim.csv')

dissim <- read.csv('mixed_dissim.csv')

cluster_h <- hclust(dist(dissim), method = "ward.D")

# Saves cluster_h object so you dont have to run it again
# save(cluster_h, file = 'cluster_h.RData')
# saveRDS(cluster_h, file = 'cluster_h.rds')

plot(cluster_h)

cutree(cluster_h, k = 5)




# Feature engineering
# Add num unique species, total basal area, total TPA -> preliminary clustering based of this


