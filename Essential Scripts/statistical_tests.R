library(tidyverse)
library(vegan)

path_of_code <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(path_of_code)
setwd("..")

source("Essential Scripts/classification_procedure_cluster.R")

#We are doing an MRPP test for examining whether there is a significant difference between groups of sampling units based on a distance matrix
#For each level 1 cluster, we examine whether there are significant differences between the corresponding level 2 clusters

#Below is a sample test for how this process works:

#labels <- read_csv("clean_data/classified_plots_labels.csv")
#df <- load_data("CAIL2")
#d <- as.matrix(dist(dissimilarity_matrix(df)))
#plots <- df %>% left_join(labels, by = c("PID", "Type", "Label")) %>% select(PID, cluster) %>% distinct()
#plots$cluster <- as.factor(plots$cluster)
#plots <- plots %>% arrange(PID)
#test <- mrpp(dat = d, grouping = plots$cluster, permutations = 9999)
#test$A
#test$Pvalue

#A measures differences between groups.
#If A > 0.3, there are strong enough differences between groups to be considered non-random
#Significance of delta is the p-value. 


#Below is the code to run for to produce p-values for all possible Level 1 types


df <- read_csv("clean_data/UMRS_FPF_clean.csv")
labels <- read_csv("clean_data/classified_plots_labels.csv") 
df <- left_join(df, labels, by = c("PID")) 
df$cluster <- as.factor(df$cluster)
df_cols_total <- df %>% filter(Type %in% (df %>% group_by(Type) %>% summarize(Count = n_distinct(PID)) %>% filter(Count > 10))$Type) %>% drop_na(Type)

df_small <- df %>% filter(Type =="ACNE2")
d <- as.matrix(dissimilarity_matrix(df_small))
df_small <- df_small %>% select(PID, cluster) %>% distinct() %>% arrange(PID)

test <- mrpp(dat = d, grouping = df_small$cluster, permutations = 9999)
result <- data.frame(Type = "ACNE2", A = test$A, p = test$Pvalue, ObservedDelta = test$delta, ExpectedDelta = test$E.delta)

completed <- c("ACNE2", "ACSA2","ACSA2 and SNAG", "ACSA2 and BENI", "ACSA2 and ULAM", "Mixed","ACSA2 and QUBI", "ACSA2 and PODE3", "ACSA2 and SALIX", "QUVE", NA)
types <- unique(df$Type)
not_completed <- types[!types %in% completed]

for(dom_species in unique(df_cols_total$Type)[unique(df_cols_total$Type) %in% not_completed]){
  print(dom_species)

  df_small <- df %>% filter(Type == dom_species)
  d <- as.matrix(dissimilarity_matrix(df_small))
  df_small <- df_small %>% select(PID, cluster) %>% distinct() %>% arrange(PID)
  
  test <- mrpp(dat = d, grouping = df_small$cluster, permutations = 9999)
  measure <- data.frame(Type = dom_species, A = test$A, p = test$Pvalue, ObservedDelta = test$delta, ExpectedDelta = test$E.delta)
  result <- rbind(result, measure)
}
write_csv(result, "mrpp2.csv")





