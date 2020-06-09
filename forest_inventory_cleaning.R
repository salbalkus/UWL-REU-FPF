library(tidyverse)

#Set working directory to the repository
setwd("C:/Users/salba/Desktop/REU/")

###ST PAUL CLEANING###
StPaul <- read_csv("Forest_Inventory_Data/mvp_p2prism_testdataclean.csv")
colnames(StPaul)
unique(StPaul$SITE)

#First, we remove observations that are outside the UMRS floodplain
#We also remove observation 5414
clean <- StPaul %>% 
  filter(SITE != "TRMB" & SITE !="RUSH") %>%
  filter(OBJECTID != 5414)

#From the original file, 336 observations were removed
#300 observations labeled as RUSH were removed
#35 observations labeled as TRMB were removed
#1 observation, 5414, was removed
nrow(filter(StPaul, SITE == "TRMB"))
nrow(filter(StPaul, SITE == "RUSH"))


#Then, we recode some of the observations to their proper species
clean[clean$OBJECTID %in% c(10722, 10724, 10786),"TR_SP"] <- "PRSE2"
clean[clean$OBJECTID %in% c(10725),"TR_SP"] <- "JUVI"
clean[clean$OBJECTID %in% c(10727, 10728, 10729, 10730),"TR_SP"] <- "POTR5"
#In total, 8 observation species names are changed

#Then, we select only the columns that we are interested in
clean <- clean %>% 
  select(PID, POOL, TR_SP, TR_DIA, TR_HLTH17, TR_HLTH)


#The below statements demonstrate that TR_HLTH17 codes are equivalent to TR_HLTH
#Therefore we do not need to recode, we can simply use TR_HLTH
clean2 <- clean[clean$TR_HLTH17 != clean$TR_HLTH,]
unique(clean2$TR_HLTH17) #Shows that there are no "D" in TR_HLTH17, or any besides the dead and NA
unique(clean2$TR_HLTH) #Shows that all in TR_HLTH are D or NA, meaning that they do not need recoding
clean2[xor(is.na(clean2$TR_HLTH17), is.na(clean2$TR_HLTH)),] #Shows that all "NA" are NA in both 17- and other years

#We wait to replace all dead observation species names with "SNAG" until end so that correct species is preserved

#In total, 3631 observations were dead. :^(
nrow(clean[clean$TR_HLTH %in% c("D"),"TR_SP"])

write_csv(clean, "StPaul_clean.csv")

###ST LOUIS CLEANING###

StLouis <- read_tsv("Forest_Inventory_Data/mvs_p2prism_3_6_2019.txt")
StLouis <- StLouis[,1:20]

#Remove Unknown species and select only the columns that we need
clean <- StLouis %>% 
  select(PID, POOL, TR_SP, TR_DIA, TR_HLTH) %>%
  filter(TR_SP != "UNKNOWN")

#only one unknown species is dropped
nrow(StLouis[StLouis$TR_SP == "UNKNOWN", ])

#10774 observations were recoded as snags
nrow(clean[clean$TR_HLTH %in% c("D"), "TR_SP"])

#Finally, we recode some of the species to the proper code
#4 observations are recoded to CAIL2
#8 observations are recoded to CORNU
#1 observation is recoded to ACSA2
nrow(clean[clean$TR_SP %in% c("CARYA"), "TR_SP"])
nrow(clean[clean$TR_SP %in% c("CODR","COSES","COFL2"), "TR_SP"])
nrow(clean[clean$TR_SP %in% c("ACSA"), "TR_SP"])

clean[clean$TR_SP %in% c("CARYA"), "TR_SP"] <- "CAIL2"
clean[clean$TR_SP %in% c("CODR","COSES","COFL2"), "TR_SP"] <- "CORNU"
clean[clean$TR_SP %in% c("ACSA"), "TR_SP"] <- "ACSA2"


write_csv(clean, "StLouis_clean.csv")

###Rock Island###
#First, set your working directory to be the folder with your Rock Island data
setwd("C:/Users/salba/Desktop/REU")
path <- paste(getwd(), "/Forest_Inventory_Data/RockIsland", sep = "")
setwd(path)

#Then, we read in the data and select only the columns that we want to use
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


#Here we confirm navigation pool membership
unique(Bunker_Chute$POOL)
unique(Pool13$POOL)
unique(Beaver_Island$POOL)
unique(P14_Smiths$POOL)
unique(P14_Steamboat$POOL) #incorrect
unique(P14_Wapsi$POOL)
unique(Big_Timber$POOL)
unique(Final_Merge_Big_Timber$POOL)
unique(Turkey_Island$POOL)
unique(Keithsburg$POOL)
unique(Odessa_Bat_TF$POOL) #incorrect
unique(Odessa_Bat_TS$POOL) #incorrect
unique(Odessa_Burn_Areas$POOL) #incorrect
unique(Huron$POOL)
unique(Pecan_Grove$POOL) #incorrect


#SITE_ID format: p21c006u004st01
#PID format:     p21c004u005st04s114p1630
#In the future, we may want to put all of the PIDs in the same format

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

#We exclude observations where DBH = 0, including all trees with no health code
#We also exclude unknown species
clean <- RockIsland %>%
  filter(TR_DIA > 0) %>%
  filter(TR_SP != "UNKNOWN")

#61 observations with DBH = 0 are removed, including all trees with no health code
nrow(RockIsland[RockIsland$TR_DIA == 0,])
#0 observations were unknown,  69 are NONE
nrow(RockIsland[RockIsland$TR_SP %in% c("UNKNOWN"),])

#we wait to recode dead tree species as "SNAG

#3814 observations were recoded as SNAG
nrow(clean[clean$TR_SP %in% c("SNAG"),"TR_SP"])

#Should we filter out "NONE" species as well?
setwd("C:/Users/salba/Desktop/REU")
write_csv(clean, "RockIsland_clean.csv")


###Combining the three datasets###
setwd("C:/Users/salba/Desktop/REU/")

StPaul <- read_csv("StPaul_clean.csv") %>% mutate(File = "StPaul", District = "StPaul")
StLouis <- read_csv("StLouis_clean.csv") %>% mutate(File = "StLouis", District = "StLouis")
RockIsland <- read_csv("RockIsland_clean.csv") %>% mutate(District = "RockIsland")

df <- bind_rows(StPaul, StLouis, RockIsland)

#Let's look at the unique species present and see if we can pick out any that should not be there
#This is how we check the species codes for errors
unique(df$TR_SP)

filter(df, TR_SP == "See 226") #What does this mean?
filter(df, TR_SP == "BLANK") #These will be removed in final filter
filter(df, TR_SP == "UNKNOWN")

#here we remove any with diameter 0 or UNKNOWN species
clean <- df %>%
  filter(TR_SP != "UNKNOWN") %>%
  filter(TR_DIA > 0)

#Only one unknown is removed
nrow(filter(df, TR_SP == "UNKNOWN"))
#6128 observations with TR_DIA == 0 are removed
nrow(filter(df, TR_DIA == 0))

###Species groupings###
#Note that the number of species recoded for each step is printed in the subsequent line of code

#i Recode dogwood
clean[clean$TR_SP %in% c("COAM2", "CORA6", "CORNU", "CORU"),"TR_SP"] <- "CORNU"
nrow(clean[clean$TR_SP %in% c("CORNU"),]) 
#25 dogwood

#ii Recode willow
clean[clean$TR_SP %in% c("SAIN", "SAIN3", "SALIX", "SANI"),"TR_SP"] <- "SALIX"
nrow(clean[clean$TR_SP %in% c("SALIX"),])
#10234 willow

#iii Recode Mulberries
clean[clean$TR_SP %in% c("MOAL", "MORU2"),"TR_SP"] <- "MOAL" #selected MOAL as the default
nrow(clean[clean$TR_SP %in% c("MOAL"),])
#1607 mulberry

#iv Combine QUEL and QUVE. Here I pick QUVE (Black Oak) as default
clean[clean$TR_SP %in% c("QUEL", "QUVE"),"TR_SP"] <- "QUVE"
nrow(clean[clean$TR_SP %in% c("QUVE"),])
#785 Black Oak

#v Recode CRATA
clean[clean$TR_SP %in% c("CRATA", "CRVI2"),"TR_SP"] <- "CRATA"
nrow(clean[clean$TR_SP %in% c("CRATA"),])
#140 hawthorn

#vi Recode ILEX
clean[clean$TR_SP %in% c("ILVE", "ILVO"),"TR_SP"] <- "ILEX"
nrow(clean[clean$TR_SP %in% c("ILEX"),])
#0 possumhaw

#vii Recode Honeysuckles
clean[clean$TR_SP %in% c("LOMA6", "LONIC", "LOTA","LOXY"),"TR_SP"] <- "LONIC"
nrow(clean[clean$TR_SP %in% c("LONIC"),])
#4 honeysuckle

#viii Recode RHAM
clean[clean$TR_SP %in% c("RHCA3", "RHFR"),"TR_SP"] <- "RHAM"
nrow(clean[clean$TR_SP %in% c("RHAM"),])
#14 buckthorn

#ix Recode Grapes
clean[clean$TR_SP %in% c("VIRI", "VITI5","VIVU"),"TR_SP"] <- "VITIS"
nrow(clean[clean$TR_SP %in% c("VITIS"),])
#1 grapes

#Then, we FINALLY recode all of the snags. We preserve a "TR_SP2" column with the original species in order to analyze the species of the snags
clean <- clean %>% mutate(TR_SP2 = TR_SP)
clean[clean$TR_HLTH %in% c("D"),"TR_SP"] <- "SNAG"

##Calculate Trees per Acre based on BasalAreaAndPointSampling.pdf
#I am not sure if the formula is correct...
clean_TPA <- clean %>%
  mutate(TR_DIA = as.numeric(TR_DIA)) %>%
  mutate(TreesPerAcre = 1 / (pi*(TR_DIA*2.75)^2) / 43560,
         BasalArea = 0.25*pi*(TR_DIA^2))

#number of NA TR_DIA
clean_TPA[is.na(clean_TPA$TR_DIA),]

#Checking the attribute values to make sure they are correct before outputting file
unique(clean_TPA$PID)
unique(clean_TPA$POOL)
unique(clean_TPA$TR_SP)
unique(clean_TPA$TR_HLTH) #looks like we have some incorrect classifications here

clean_TPA[clean_TPA$TR_HLTH %in% c("H"), "TR_HLTH"] <- "V"
clean_TPA[clean_TPA$TR_HLTH %in% c("NT"),] #should we remove "NT"?

write_csv(clean_TPA, "UMRS_FPF_clean.csv")
