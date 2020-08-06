#This script tests the process of hierarchical clustering and using a decision tree to select the number of clusters for a few different species.
#This approach was ultimately scrapped

library(ggsci)
library(rpart.plot)
library(vegan)

path_of_code <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(path_of_code)

source("classification_procedure.R")

#Load the data and apply the (scrapped) classification procedure

acsa2 <- load_data("ACSA2")
d <- as.matrix(read_csv("dissimilarity_matrix.csv"))
process <- best_clustering(acsa2, d, "ACSA2", 10)
test <- process[[1]]
nrow(test)
test_tree <- process[[2]]
rpart.plot(test_tree)

ggplot(test) + geom_point(aes(x = log(TPA_ACSA2), y = log(BA_ACSA2), color = as.factor(cluster))) + scale_color_jco() + theme_light()

# Mean Dissimilarity Matrix
md <- with(test, meandist(d, grouping = cluster))
summary(md)
plot(md)

mp <- with(test, mrpp(d, grouping = cluster, weight.type = 1))
#delta is the overall weighted mean of within-group means
#of the pairwise dissimilarities
mp
#Demonstrates statistical significance
#Should a post-hoc test be performed? What sort of test?



#Analysis of variance using distance metrics
result <- adonis2(d ~ cluster, data = test)
result
#According to this analysis of variance, there are differences btw clusters

#Now we look at CAPs to see how related each cluster is
df <- read_csv("clean_data/UMRS_FPF_clean.csv")
labels <- read_csv("clean_data/plot_classification.csv")
df_cols <- left_join(df, labels, by = "PID") %>% select(PID, TR_SP, BasalArea, TreesPerAcre, Type, Label)
df_acsa2 <- filter(df_cols, Type == "ACSA2") %>% left_join(select(test, PID, cluster), by = "PID")

TPA_bins = 1 / (pi * (seq(1:106)*2.75)^2) / 43560
BA_bins = 0.25*pi*(seq(1:106)^2)

test <- stratifyvegdata(df_acsa2, sizes1 = BA_bins, plotColumn = "cluster", speciesColumn = "TR_SP", abundanceColumn = "TreesPerAcre", size1Column = "BasalArea", cumulative = TRUE )
dissim2 <- vegdiststruct(test, method = "manhattan")
cluster <- hclust(dissim2, method = "single")
plot(cluster)


###Cottonwood###

pode3 <- load_data("PODE3")
d <- dissimilarity_matrix(pode3)
process <- best_clustering(pode3, d, "PODE3", 20)
test <- process[[1]]
test_tree <- process[[2]]
rpart.plot(test_tree)

ggplot(test) + geom_point(aes(x = log(TPA_PODE3), y = log(BA_PODE3), color = as.factor(cluster))) + scale_color_jco() + theme_light()

#there is clearly an issue - sometimes, a cluster will be too insignificant to be picked out by the decision tree. In this case, what should we do?

#We should also put a minimum number of observations in each bin - say, 5% of the total observations?
#The minimum number of clusters could also be something like 5% of total observations

frpe <- load_data("FRPE")
d <- dissimilarity_matrix(frpe)
process <- best_clustering(frpe, d, "FRPE", 20, os = FALSE)
test <- process[[1]]
test_tree <- process[[2]]
rpart.plot(test_tree)

ggplot(test) + geom_point(aes(x = log(TPA_FRPE), y = log(BA_FRPE), color = as.factor(cluster))) + scale_color_jco() + theme_light()

nrow(test)
