library(tidyverse, quietly = TRUE)
library(vegclust, quietly = TRUE)
library(rpart, quietly = TRUE)
library(infotheo, quietly = TRUE)


#Load in the data that will be used for clustering
load_data <- function(dom_species){

  df <- read_csv("clean_data/UMRS_FPF_clean.csv")
  labels <- read_csv("clean_data/plot_classification.csv")

  df_cols <- left_join(df, labels, by = "PID") %>% select(PID, TR_SP, TR_DIA, BasalArea, TreesPerAcre, Type, Label) %>% filter(Type == dom_species)
  return(df_cols)
}


#Classification output for a single dominant species type
#This needs to be tested, and introspection must be able to be performed
classify_type <- function(type){

  df <- load_data(Type)
  pioneer <- c("PODE3","SALIX")
  metrics <- df %>% group_by(PID) %>% summarize(Species = n_distinct(TR_SP), 
                                     TPA = sum(TreesPerAcre),
                                     BA = sum(BasalArea), 
                                     TPA_pioneer = sum(TreesPerAcre[TR_SP %in% pioneer]),
                                     BA_pioneer = sum(BasalArea[TR_SP %in% pioneer]),
                                     TPA_SNAG = sum(TreesPerAcre[TR_SP == "SNAG"]),
                                     BA_SNAG = sum(BasalArea[TR_SP == "SNAG"])
                                     )
  
  
  
 
}

hard_mast <- c("QUPA2","QUBI","QUVE","QUMA2","QULY","CACO15","QURU","CALA21","CAOV2","QUAL")
food <- c("CAIL2","CEOC","JUNI","PRSE2","MAPO")
pioneer <- c("PODE3","SALIX")
shade_tolerant <- c("ACNE2","MOAL","MORUS")
other <- c("FRPE","ULAM","PLOC","BENI","FOAC","GLTR","DIVI5","TIAM","GYDI","ROPS","CEOC2","CRATA","FRNI","OTHER","TADI2","PIRE","CORNU")


df <- load_data("ACNE2")
df %>% group_by(PID) %>% summarize(Species = n_distinct(TR_SP), 
                                     TPA = sum(TreesPerAcre),
                                     BA = sum(BasalArea), 
                                     TPA_pioneer = sum(TreesPerAcre[TR_SP %in% pioneer]),
                                     BA_pioneer = sum(BasalArea[TR_SP %in% pioneer]),
                                     TPA_SNAG = sum(TreesPerAcre[TR_SP == "SNAG"]),
                                     BA_SNAG = sum(BasalArea[TR_SP == "SNAG"])
                                     )

