library(tidyverse)

path_of_code <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(path_of_code)
setwd("..")

#Combine all of the land use data files together
StLouis <- read_csv("Datasets/Mapping/Land Cover Overlay Results/StLouis_P2_2010LCLU_Join.txt")
StLouis <- StLouis %>% mutate(UND_HT = as.character(UND_HT), COL_DATE = as.character(COL_DATE))
StPaul <- read_csv("Datasets/Mapping/Land Cover Overlay Results/StPaul_P2_2010LCLU_Join.txt")
data <- bind_rows(StLouis, StPaul)
data <- bind_rows(data, read_csv("Datasets/Mapping/Land Cover Overlay Results/BeaverIsland_P2_2010LCLU_Join.txt"))
data <- bind_rows(data, read_csv("Datasets/Mapping/Land Cover Overlay Results/BigTimber_P2_2010LCLU_Join.txt"))
data <- bind_rows(data, read_csv("Datasets/Mapping/Land Cover Overlay Results/BunkerChute_P2_2010LCLU_Join.txt"))
data <- bind_rows(data, read_csv("Datasets/Mapping/Land Cover Overlay Results/FinalMergeBigTimber_P2_2010LCLU_Join.txt"))
data <- bind_rows(data, read_csv("Datasets/Mapping/Land Cover Overlay Results/Huron_P2_2010LCLU_Join.txt"))
data <- bind_rows(data, read_csv("Datasets/Mapping/Land Cover Overlay Results/Keithsburg_P2_2010LCLU_Join.txt"))
data <- bind_rows(data, read_csv("Datasets/Mapping/Land Cover Overlay Results/OdessaBatTF_P2_2010LCLU_Join.txt"))
data <- bind_rows(data, read_csv("Datasets/Mapping/Land Cover Overlay Results/OdessaBatTS_P2_2010LCLU_Join.txt"))
data <- bind_rows(data, read_csv("Datasets/Mapping/Land Cover Overlay Results/OdessaBurnAreas_P2_2010LCLU_Join.txt"))
P14Smiths <- read_csv("Datasets/Mapping/Land Cover Overlay Results/P14Smiths_P2_2010LCLU_Join.txt") %>% mutate(DEVICEID = as.character(DEVICEID))
data <- bind_rows(data, P14Smiths)
P14Steamboat <- read_csv("Datasets/Mapping/Land Cover Overlay Results/P14Steamboat_P2_2010LCLU_Join.txt") %>% mutate(PLOT = as.character(PLOT))
data <- bind_rows(data, P14Steamboat)
P14Wapsi <- read_csv("Datasets/Mapping/Land Cover Overlay Results/P14Wapsi_P2_2010LCLU_Join.txt") %>% mutate(UND_HT = as.character(UND_HT), PLOT = as.character(PLOT), PLOT_NEW = as.character(PLOT_NEW))
data <- bind_rows(data, P14Wapsi)
PecanGroveTF <- read_csv("Datasets/Mapping/Land Cover Overlay Results/PecanGroveTF_P2_2010LCLU_Join.txt") %>% mutate(PLOT = as.character(PLOT))
data <- bind_rows(data, PecanGroveTF)
Pool13 <- read_csv("Datasets/Mapping/Land Cover Overlay Results/Pool13_P2_2010LCLU_Join.txt") %>% mutate(PLOT = as.character(PLOT))
data <- bind_rows(data, Pool13)
TurkeyIsland <- read_csv("Datasets/Mapping/Land Cover Overlay Results/TurkeyIsland_P2_2010LCLU_Join.txt") %>% mutate(PLOT = as.character(PLOT), DEVICEID = as.character(DEVICEID))
data <- bind_rows(data, TurkeyIsland)

#Look at the different types of data and join with our own classification
unique(data$CLASS_31_N)
labels <- read_csv("clean_data/classified_plots_labels.csv")
labels$Level2 <- paste(labels$Type, labels$cluster, sep = ".")

df <- left_join(labels, data, by = "PID")
write_csv(df, "clean_data/land_use_combined.csv")

#Create contigency table
ctable <- table(df$Level2, df$CLASS_31_N)
write.table(ctable, "clean_data/land_use_contigency.csv", sep=",")
