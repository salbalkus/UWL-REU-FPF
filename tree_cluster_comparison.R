library(tidyverse)
library(vegclust)
library(cluster)
library(rpart)
library(rpart.plot)
library(zoo)
library(vegan)
library(infotheo)
library(ggsci)

path_of_code <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(path_of_code)

source("classification_procedure.R")

plots <- read_csv("clean_data/plots_nonrel.csv")
plots_acsa2 <- plots %>% filter(Type == "ACSA2")
plots_acsa2


obs <- read_csv("clean_data/UMRS_FPF_clean.csv")
labels <- read_csv("clean_data/plot_classification.csv")
obs <- left_join(obs, labels, by = "PID")

feature_engineer <- function(obs, name, dom1, dom2){
  
  obs_target <- obs %>% filter(Type == name)
  
  #Feature Engineering
  hard_mast <- c("QUPA2","QUBI","QUVE","QUMA2","QULY","CACO15","QURU","CALA21","CAOV2","QUAL")
  food <- c("CAIL2","CEOC","JUNI","PRSE2","MAPO")
  pioneer <- c("PODE3","SALIX")
  shade_tolerant <- c("ACNE2","MOAL","MORUS")
  other <- c("FRPE","ULAM","PLOC","BENI","FOAC","GLTR","DIVI5","TIAM","GYDI","ROPS","CEOC2","CRATA","FRNI","OTHER","TADI2","PIRE","CORNU")
  
  fe_target<- obs_target %>% group_by(PID) %>% 
    summarize(
      Total_TPA = sum(TreesPerAcre),
      Total_BA = sum(BasalArea),
      Num_Species = n_distinct(TR_SP),
      Dom1_TPA = sum(TreesPerAcre[TR_SP == dom1]),
      Dom1_BA = sum(BasalArea[TR_SP == dom1]),
      Dom2_TPA = sum(TreesPerAcre[TR_SP == dom2]),
      Dom2_BA = sum(BasalArea[TR_SP == dom2]),
      SNAG_TPA = sum(TreesPerAcre[TR_SP == "SNAG"]),
      SNAG_BA = sum(BasalArea[TR_SP == "SNAG" ]),
      HARDMAST_TPA = sum(TreesPerAcre[TR_SP %in% hard_mast]),
      HARDMAST_BA = sum(BasalArea[TR_SP %in% hard_mast ]),
      FOOD_TPA = sum(TreesPerAcre[TR_SP %in% food]),
      FOOD_BA = sum(BasalArea[TR_SP %in% food ]),
      PIONEER_TPA = sum(TreesPerAcre[TR_SP %in% pioneer]),
      PIONEER_BA = sum(BasalArea[TR_SP %in% pioneer ]),
      SHADE_TPA = sum(TreesPerAcre[TR_SP %in% shade_tolerant]),
      SHADE_BA = sum(BasalArea[TR_SP %in% shade_tolerant ]),
      OTHER_TPA = sum(TreesPerAcre[TR_SP %in% other]),
      OTHER_BA = sum(BasalArea[TR_SP %in% other ])
    )
    
  return(fe_target)
}

#Test various types
target <- "ACSA2 and PODE3"
fe_test <- feature_engineer(obs, target, "ACSA2","PODE3")
form <- paste( "cluster ~", paste0(colnames(fe_test)[2:(ncol(fe_test)-2)], collapse = " + "))

dissim <- read_csv("dissimilarity_matrix.csv")
dissim <- dissimilarity_matrix(load_data(target))
dissim <- as.matrix(dissim)
cluster_h <- hclust(as.dist(dissim), method = "ward.D2")

cut <- cutree(cluster_h, k = 10)
fe_test$cluster <- as.factor(cut)

tree <- rpart(data = fe_test, formula = form, method = "class", 
              parms = list(split = "information"),
              control = rpart.control(minbucket = 1))
rpart.plot(tree)

ggplot(fe_test) + geom_point(aes(x = log(Dom1_TPA), y = log(Dom2_TPA), color = cluster)) + theme_light() + scale_color_jco()

tab <- table(fe_test$cluster, predict(tree, fe_test, type = "vector"))
sum(diag(tab)) / sum(tab)


#maxdepth = ceiling(log(2*10,2))



#############THIS IS OLD CODE FOR TESTING V-MEASURE ON CLUSTERING ################

#Homogeneity and Completeness
# here we assume the Ward clustering to be the "true classes"
plots_acsa2$tree <- predict(tree, plots_acsa2, type = "vector")
conf <- table(as.factor(plots_acsa2$cluster), factor(plots_acsa2$tree, levels = seq(1:10)))

h <- 1 - condentropy(plots_acsa2$cluster, plots_acsa2$tree) / entropy(plots_acsa2$cluster)
c <- 1 - condentropy(plots_acsa2$tree, plots_acsa2$cluster) / entropy(plots_acsa2$tree)

#Validity measure - combines homogeneity and completeness

validity <- 2 * ((h*c) / (h + c))

#Now we compare across multiple clusters
max_clusters <- 11
vmeasures <- vector(length = max_clusters - 1)
accuracies <- vector(length = max_clusters - 1)
trees <- vector("list", length = max_clusters - 1)

for(n in 2:max_clusters){
  cut <- cutree(cluster_h, k = n)
  plots_acsa2$cluster <- cut
  
  tree <- rpart(data = plots_acsa2, formula = form, method = "class", 
                parms = list(split = "information"),
                control = rpart.control(maxdepth = ceiling(log(2*10,2)),cp = 0, minbucket = 1))
  trees[n-1] <- tree
  plots_acsa2$tree <- predict(tree, plots_acsa2, type = "vector")
  
  h <- 1 - condentropy(plots_acsa2$cluster, plots_acsa2$tree) / entropy(plots_acsa2$cluster)
  c <- 1 - condentropy(plots_acsa2$tree, plots_acsa2$cluster) / entropy(plots_acsa2$tree)
  
  vmeasures[n-1] <- 2 * ((h*c) / (h + c))
  accuracies[n-1] <- sum(diag(table(plots_acsa2$cluster, plots_acsa2$tree))) / nrow(plots_acsa2)
}
#higher validity measures are better
wrap <- data.frame(Clusters = (seq(1:(max_clusters-1)) + 1), V.measure = vmeasures, Accuracy = accuracies)
ggplot(wrap, mapping = aes(x = Clusters, y = V.measure)) + geom_point() + geom_line() + theme_light()
ggplot(wrap, mapping = aes(x = Clusters, y = Accuracy)) + geom_point() + geom_line() + theme_light()


best_k <- which.max(accuracies) + 1
best_k

best <- cutree(cluster_h, best_k)
plots_acsa2$cluster <- best

tree <- rpart(data = plots_acsa2, formula = form, method = "class", 
              parms = list(split = "information"),
              control = rpart.control(cp = 0, minbucket = 1))

rpart.plot(tree)
#Hence, we find that for silver maples, cutting the Ward cluster at k = 5 is the best choice for validity (with max clusters equal to 20)
#With max clusters at 100, the best choice is 94, which is obviously far too many

