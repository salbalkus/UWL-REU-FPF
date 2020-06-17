library(tidyverse)
library(lubridate)

# in case of changing directory, this will be the directory where
# this file is located.
path_of_code <- rprojroot::find_rstudio_root_file()

# Imports relevant csv files to get the plot level information 
# as well as all the species that we recorded
clean_data <- read_csv('./clean_data/UMRS_FPF_clean.csv')

# Obtains unique species that were observed
species <- clean_data %>% count(TR_SP, sort = T) %>%
  .$TR_SP

df <- clean_data

plot_freq <- df %>%
  group_by(PID, TR_SP) %>%
  summarize(Freq = n()) %>%
  spread(TR_SP, Freq) %>%
  replace(is.na(.), 0)

plot_BA <- df %>%
  group_by(PID, TR_SP) %>%
  summarize(BA = sum(BasalArea)) %>%
  spread(TR_SP, BA) %>%
  replace(is.na(.), 0)

plot_rel_BA<- df %>%
  group_by(PID, TR_SP) %>%
  summarize(BA = sum(BasalArea)) %>%
  group_by(PID) %>%
  mutate(rel_BA = BA / sum(BA)) %>%
  select(-BA) %>%
  spread(TR_SP, rel_BA) %>%
  replace(is.na(.), 0)

plot_TPA <- df %>%
  group_by(PID, TR_SP) %>%
  summarize(TPA = sum(TreesPerAcre)) %>%
  spread(TR_SP, TPA) %>%
  replace(is.na(.), 0)

plot_rel_TPA <- df %>%
  group_by(PID, TR_SP) %>%
  summarize(TPA = sum(TreesPerAcre)) %>%
  group_by(PID) %>%
  mutate(rel_TPA = TPA / sum(TPA)) %>%
  select(-TPA) %>%
  spread(TR_SP, rel_TPA) %>%
  replace(is.na(.), 0)

plots <- inner_join(plot_BA, plot_rel_BA, by = c("PID"), suffix = c("_BA","_rel_BA"))
plots <- inner_join(plot_freq, plots, by = c("PID"))

plots_tpa <- inner_join(plot_TPA, plot_rel_TPA, by = c("PID"), suffix = c("_TPA","_rel_TPA"))
plots <- inner_join(plots_tpa, plots, by = c("PID"))
plots
# Adds a class column to the plot data frame
# All entries should be NA to start

plot_level <- plots

plot_level <- plot_level %>% mutate(class = NA)
plot_level$class

# Main function for classifying the plots
# First starts out with checking to see if it's dominant
# If that isn't the case it then checks to see if it's codominant
# Otherwise it's classified as mixed.
# If the plot is classified as codominant, the order of the species in its
# classification will be in order of stem count.  With the more abundant species
# coming first.
# This function takes an individual plot as an input
plot_classifier <- function(plot){

  # Finds percentage of total trees each species makes in the plot
  percentage <- plot[paste(species, 'rel_TPA', sep = '_')]
  percentage_order <- order(-percentage)

  # Finds the most abundant species
  s1 <- species[percentage_order[1]]

  
  # single species dominance check
  if ((percentage[paste(s1, 'rel_TPA', sep = '_')] > 0.8) & (plot[paste(s1, 'rel_BA', sep = '_')] > 0.8)){
    output <- paste('D', s1, sep = '_')
    return(output)
  }

  # multispecies codominance
  
  # Second most abundant species
  
  # These are variables to keep track of the percent of tree and tpa that
  # we go through in the following for loop.  This will allow us to break the 
  # for loop if either exceed 20% since in that case, it would be impossible for
  # the forest to be codominant, and we can immediately classify it as mixed.
  extra_percent <- 0
  extra_TPA <- 0
  
  # This loops iterates through the rest of the species in order of descending stem count
  for (i in 2:(length(species))){  
    # gets species 2 to check
    s2 <- species[percentage_order[i]]
  
    # Checks criteria that each individual species must meet to be considered codominant
    s1_crit <- ((percentage[paste(s1, 'rel_TPA', sep = '_')] >= 0.2) | (plot[paste(s1, 'rel_BA', sep = '_')] >= 0.2))
    s2_crit <- ((percentage[paste(s2, 'rel_TPA', sep = '_')] >= 0.2) | (plot[paste(s2, 'rel_BA', sep = '_')] >= 0.2))
    
    # adds the percentage of tree and tpa that species 2 makes up
    # if either is above 20% after checking the criteria, then we break the loop
    extra_percent <- extra_percent + percentage[paste(s2, 'rel_TPA', sep = '_')]
    extra_TPA <- extra_TPA + plot[paste(s2, 'rel_BA', sep = '_')]
    
    if (s1_crit & s2_crit){
      # If both criteria are met, then we check if the total percentage and total TPA 
      # is greater than 80%
      tot_percent <- percentage[paste(s1, 'rel_TPA', sep = '_')] + percentage[paste(s2, 'rel_TPA', sep = '_')]
      tot_TPA <-plot[paste(s1, 'rel_BA', sep = '_')] + plot[paste(s2, 'rel_BA', sep = '_')]
  
      if ((tot_percent > 0.8) & (tot_TPA > 0.8)){
        # if both are above 80%, then we classify the forest as a codominant
        # with the two species
        output <- paste('CD', sort(c(s1,s2))[1], sort(c(s1,s2))[2], sep ='_')
        return(output)
      }
    }
    if ((extra_percent >= 0.2) | (extra_TPA >= 0.2)){
      # If either of these are met, then species 1 and any other species 
      # cannot make up at least 80% of the trees/TPA.  So the forest then
      # must be a mixed forest
      return('M')
    }
  }  
  # in case something goes wrong and the loop has to finish it should then
  # be classified as mixed
  return('M')
}

plot_classifier(plot_level[1,])

start <- now() # used for timing the classification algorithm
for (i in 1:nrow(plot_level)){
  plot_level$class[i] <- plot_classifier(plot_level[i, ]) 
  
  if (i %% 250 == 0){
    # lets us know current progress of the for loop
    print(i)
    print(now() - start)
  }
}
end <- now() # end of classification algorithm
end - start # cam run this to see how long it took

# writes a csv to the clean_data directory called plot_level_with_class.csv
write_csv(plot_level, './clean_data/plot_level_with_class3.csv')

# can see all the unique classes
unique(plot_level$class)

# sorts the classes based on count.  Can see that mixed is the most abundant
# would probably then want to do some sort of clustering algorithm on just the 
# mixed forests since this is such a broad category
plot_level %>% ungroup() %>% 
  count(class, sort = T)

paste('CD', sort(c('v', 'a'))[1], sort(c('v', 'a'))[2], sep ='_')

x <- plot_level %>% ungroup %>%
  select(class) %>% 
  mutate('type' = NA, 'sp1' = NA, 'sp2' = NA)

x[c('type', 'sp1', 'sp2')] <- plot_level$class %>% str_split_fixed(., '_', n = Inf)
x %>% group_by(type) %>% 
  summarize(count = n_distinct(class))
x
?ungroup

plot_level %>% filter(class == 'D_SNAG')

