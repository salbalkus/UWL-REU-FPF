#This script merges the uncleaned data files into one file to provide comparisons between cleaned and uncleaned data

library(tidyverse)

path_of_code <- dirname(rstudioapi::getSourceEditorContext()$path)
datasets <- paste(path_of_code, '/Datasets', sep = '')
clean_data_repository <- paste(path_of_code, '/clean_data', sep = '')
setwd(datasets)

setwd(paste(datasets, '/Forest_Inventory_Data/RockIsland', sep =''))

Beaver_Island <- read_csv("Beaver_Island_Prism_2014.txt") %>% select(PID, POOL, TR_SP, TR_DIA, TR_HLTH) %>% mutate(File = "Beaver_Island_Prism_2014.txt")
Big_Timber <- read_csv("Big_Timber_Prism_Final_Contr.txt") %>% select(PID, POOL, TR_SP, TR_DIA, TR_HLTH) %>% mutate(File = "Big_Timber_Prism_Final_Contr.txt")
Bunker_Chute <- read_csv("Bunker_Chute_Prism_2014.txt") %>% select(PID, POOL, TR_SP, TR_DIA, TR_HLTH) %>% mutate(File = "Bunker_Chute_Prism_2014.txt")
Final_Merge_Big_Timber <- read_csv("Final_Merge_Big_Timber_Prism.txt") %>% select(PID, POOL, TR_SP, TR_DIA, TR_HLTH) %>% mutate(File = "Final_Merge_Big_Timber_Prism.txt")

Huron <- read_csv("Huron_Prism_2012.txt") %>% select(PID, POOL, TR_SP, TR_DIA2, TR_HLTH) %>% mutate(File = "Huron_Prism_2012.txt")
Keithsburg <- read_csv("Keithsburg_Prism_2015.txt") %>% select(PID, POOL, TR_SP, TR_DIA2, TR_HLTH) %>% mutate(File = "Keithsburg_Prism_2015.txt")
colnames(Huron) <- c("PID","POOL","TR_SP","TR_DIA","TR_HLTH", "File")
colnames(Keithsburg) <- c("PID","POOL","TR_SP","TR_DIA","TR_HLTH", "File")

Odessa_Bat_TF <- read_csv("Odessa_Bat_TF_Prism_2018.txt") %>% select(PID, POOL, TR_SP, TR_DIA, TR_HLTH) %>% mutate(File = "Odessa_Bat_TF_Prism_2018.txt")
Odessa_Bat_TS <- read_csv("Odessa_Bat_TS_Prism_2018.txt") %>% select(PID, POOL, TR_SP, TR_DIA, TR_HLTH) %>% mutate(File = "Odessa_Bat_TS_Prism_2018.txt")
Odessa_Burn_Areas <- read_csv("Odessa_Burn_Areas_Prism_2010.txt") %>% select(PID, POOL, TR_SP, TR_DIA, TR_HLTH) %>% mutate(File = "Odessa_Burn_Areas_Prism_2010.txt")
P14_Smiths <- read_csv("P14_Smiths_Prism.txt") %>% select(PID, POOL, TR_SP, TR_DIA, TR_HLTH) %>% mutate(File = "P14_Smiths_Prism.txt")

P14_Steamboat <- read_csv("P14_Steamboat_Prism.txt") %>% select(PID_NEW, POOL_1, TR_SP, TR_DIA, TR_HLTH) %>% mutate(File = "P14_Steamboat_Prism.txt")
colnames(P14_Steamboat) <- c("PID","POOL","TR_SP","TR_DIA","TR_HLTH", "File")

P14_Wapsi <- read_csv("P14_Wapsi_Prism.txt") %>% mutate(PID = paste(Site_ID, "sXXXXp", PLOT_NEW, sep = "")) %>% select(PID, POOL_1, TR_SP, TR_DIA, TR_HLTH2) %>% mutate(File = "P14_Wapsi_Prism.txt")
colnames(P14_Wapsi) <- c("PID","POOL","TR_SP","TR_DIA","TR_HLTH", "File")

#Here we have to split the file, since some observations have a PID and some have PID_NEW
Pecan_Grove <- read.csv("Pecan_Grove_Prism_Merge.txt", stringsAsFactors = FALSE)# %>% select(PID_NEW, POOL, TR_SP, TR_DIA2, TR_HLTH) %>% mutate(File = "Pecan_Grove_Prism_Merge.txt")
Pecan_Grove_new <- Pecan_Grove %>% 
  select(PID_NEW, POOL, TR_SP, TR_DIA2, TR_HLTH) %>% 
  filter(!is.na(PID_NEW) & PID_NEW != " ")
colnames(Pecan_Grove_new) <- c("PID","POOL","TR_SP","TR_DIA","TR_HLTH")
Pecan_Grove_old <- Pecan_Grove %>% 
  select(PID, POOL, TR_SP, TR_DIA2, TR_HLTH) %>% 
  filter(!is.na(PID)& PID != " ")
colnames(Pecan_Grove_old) <- c("PID","POOL","TR_SP","TR_DIA","TR_HLTH")

Pecan_Grove <- rbind(Pecan_Grove_old, Pecan_Grove_new)
Pecan_Grove <- mutate(Pecan_Grove, File = "Pecan_Grove_Prism_Merge.txt")

#Pool13 requires creation of a PID, since it does not have a PID column
Pool13 <- read_csv("Pool13_Prism.txt")%>%
  mutate(PID = paste(SITE_ID, PL_NUM_2, "p0")) %>% 
  select(PID, POOL, TR_SP, TR_DIA_2, TR_HLTH) %>% 
  mutate(File = "Pool13_Prism.txt")
colnames(Pool13) <- c("PID","POOL","TR_SP","TR_DIA","TR_HLTH", "File")

Turkey_Island <- read_csv("Turkey_Island_Prism.txt") %>% select(PID_1, POOL_1, TR_SP, TR_DIA, TR_HLTH) %>% mutate(File = "Turkey_Island_Prism.txt")
colnames(Turkey_Island) <- c("PID","POOL","TR_SP","TR_DIA","TR_HLTH", "File")


RockIsland <- bind_rows(Bunker_Chute, 
                        Pool13, 
                        Beaver_Island, 
                        P14_Smiths,
                        P14_Steamboat,
                        P14_Wapsi,
                        Big_Timber,
                        Final_Merge_Big_Timber,
                        Turkey_Island,
                        Keithsburg,
                        Odessa_Bat_TF,
                        Odessa_Bat_TS,
                        Odessa_Burn_Areas,
                        Huron,
                        Pecan_Grove)

setwd("..")

StLouis <- read_tsv("mvs_p2prism_3_6_2019.txt")
StLouis <- StLouis[,1:20]
StLouis <- StLouis %>% 
  select(PID, POOL, TR_SP, TR_DIA, TR_HLTH) %>%
  mutate(File = "StLouis")

StPaul <- read_csv("mvp_p2prism_testdataclean.csv")
StPaul <- StPaul %>% 
  select(PID, POOL, TR_SP, TR_DIA, TR_HLTH) %>%
  mutate(File = "StPaul")


df <- bind_rows(StPaul, StLouis, RockIsland)

setwd(clean_data_repository)
write_csv(df, "Unclean_combined.csv")