library(tidyverse)
library(rlist)
library(gridExtra)

path_of_code <- dirname(rstudioapi::getSourceEditorContext()$path)
datasets <- paste(path_of_code, '/Datasets', sep = '')
clean_data_repository <- paste(path_of_code, '/clean_data', sep = '')

##### Second other question #####

# This first section is code to answer the second 'Other question'.  This is a script that will generate another dataframe that states if a tree species
# is present in that pool.  And it will give the total trees per acre (Total_TPA), absolute trees per acre for each species (SPECIES_ATPA), and
# relative trees per acre for each species (SPECIES_RTPA)


df <- read_csv(paste(path_of_code, '/clean_data/UMRS_FPF_clean.csv', sep =''))

df

species <- unique(df$TR_SP)

plot_level <- tibble(PID = unique(df$PID))

plot_level <- plot_level %>% arrange(PID)

x <- df %>% group_by(PID) %>% 
  summarize(species[1] %in% TR_SP)

x

for (i in 1:length(species)){
  present <- (df %>% group_by(PID) %>% 
    summarize(p = (species[i] %in% unique(TR_SP))))
  
  plot_level <- left_join(plot_level, present, by = 'PID')
  colnames(plot_level)[i+1] <- species[i]
}

TPA <- df %>% group_by(PID) %>% 
  summarise(Total_TPA = sum(TreesPerAcre))
TPA

for (i in 1:length(species)){
  sp_TPA <- df %>% filter(TR_SP == species[i]) %>% 
    group_by(PID) %>% 
    summarise(sum(TreesPerAcre))
  
  TPA <- TPA %>% left_join(sp_TPA, by = 'PID')
  colnames(TPA)[i + 2] <- paste(species[i], '_ATPA', sep = '')
}
TPA
TPA[is.na(TPA)] <- 0
TPA

plot_level <- plot_level %>% left_join(TPA, by = 'PID')

RTPA <- (TPA %>% select(ACSA2_ATPA:NONE_ATPA)) / (TPA$Total_TPA)
RTPA <- cbind(TPA$PID, RTPA)
colnames(RTPA) <- c('PID', paste(species, '_RTPA', sep = ''))

RTPA
plot_level <- plot_level %>% left_join(RTPA, by = 'PID')


setwd(clean_data_repository)
write_csv(plot_level, 'plot_level.csv')
setwd(path_of_code)

##### First other question #####

# This section has a function that answers the first other question.  So the function will be able to filter rare species based on the number of
# unique plots it was found in

exclude_rare_species <- function(df, min_plot_count){
  # This function will take in a dataframe in the same form as our cleaned data frame.  It will then filter out any species that weren't in
  # enough unique plots, which is user defined by the min_plot_count argument.  
  
  # This just generates all of the species to be excluded
  excluded <- (df %>% group_by(TR_SP) %>% 
    summarize(plots = n_distinct(PID)) %>% 
    filter(plots < min_plot_count))$TR_SP
  
  # This filters to dataframe so only species not included in the excluded list will pass through
  filtered_df <- df %>% filter(!(TR_SP %in% excluded))
  
  # returns the filtered dataframe
  return(filtered_df)
}
