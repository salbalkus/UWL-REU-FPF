
##### Imports #####


library(tidyverse)

path_of_code <- rprojroot::find_rstudio_root_file()

noah <- read_csv('./clean_data/plot_level_with_class2.csv')
sal <- read_csv('./clean_data/plot_classification.csv')
plot_level <- read_csv('./clean_data/plots.csv')
all_data <- read_csv('./clean_data/UMRS_FPF_clean.csv')

species <- unique(all_data$TR_SP)

plot_classifier <- function(plot){
  
  # Finds percentage of total trees each species makes in the plot
  percentage <- plot[species]/sum(plot[species])
  percentage_order <- order(-percentage)
  
  # Finds the most abundant species
  s1 <- species[percentage_order[1]]
  
  # single species dominance check
  if ((percentage[s1] > 0.8) & (plot[paste(s1, 'rel_TPA', sep = '_')] > 0.8)){
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
    s1_crit <- ((percentage[s1] > 0.2) | (plot[paste(s1, 'rel_TPA', sep = '_')] > 0.2))
    s2_crit <- ((percentage[s2] > 0.2) | (plot[paste(s2, 'rel_TPA', sep = '_')] > 0.2))
    
    # adds the percentage of tree and tpa that species 2 makes up
    # if either is above 20% after checking the criteria, then we break the loop
    extra_percent <- extra_percent + percentage[s2]
    extra_TPA <- extra_TPA + plot[paste(s2, 'rel_TPA', sep = '_')]
    
    if (s1_crit & s2_crit){
      # If both criteria are met, then we check if the total percentage and total TPA 
      # is greater than 80%
      tot_percent <- percentage[s1] + percentage[s2]
      tot_TPA <-plot[paste(s1, 'rel_TPA', sep = '_')] + plot[paste(s2, 'rel_TPA', sep = '_')]
      
      if ((tot_percent > 0.8) & (tot_TPA > 0.8)){
        # if both are above 80%, then we classify the forest as a codominant
        # with the two species
        output <- paste('CD', s1, s2, sep ='_')
        return(output)
      }
    }
    if ((extra_percent > 0.2) | (extra_TPA > 0.2)){
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

##### Cleaning the classifications to be in the same format #####

noah <- noah %>% select(PID, class) %>% 
  mutate(sp1 = NA, sp2 = NA, type = NA)

sal <- sal %>% select(PID, Type, Label) %>% 
  mutate(sp1 = NA, sp2 = NA, type = NA)
noah



noah[c('sp1', 'sp2', 'type')] <- noah$class %>% str_split_fixed(., '_', n = Inf)

noah$class

noah[c('sp1', 'sp2', 'type')]

noah_m <- noah %>% filter(sp1 == 'M') %>% 
  replace(., 'type', 'M') %>% 
  replace('sp1', '')

noah_d <- noah %>% filter(sp2 == 'D') %>% 
  replace('type', 'D') %>% 
  replace('sp2', '')

noah_cd <- noah %>% filter(type == 'CD')

noah_fix <- bind_rows(noah_m, noah_cd, noah_d) %>% select(PID, sp1, sp2, type)
noah_fix

sal[c('sp1', 'sp2')] <- sal$Type %>% str_split_fixed(.,' and ', n = Inf)

sal <- sal %>% select(PID, sp1, sp2, Type, Label)
colnames(sal)[4] <- 'type'

sal_m <- sal %>% filter(Label == 'Mixed') %>% 
  replace('type', 'M')

sal_d <- sal %>% filter(Label == 'Dominant') %>% 
  replace('type', 'D')

sal_cd <- sal %>% filter(Label == 'Codominant') %>% 
  replace('type', 'CD')

sal_fix <- bind_rows(sal_m, sal_d, sal_cd) %>% select(PID, sp1, sp2, type)

sal_fix
noah_fix

?inner_join

##### Analysis of the classifications #####

comparison <- full_join(noah_fix, sal_fix, by = 'PID', suffix = c('_noah', '_sal'))
comparison %>% filter(type_noah != type_sal)

# This was the first one to appear on the above table
# Noah's function classifies it as mixed
# Sal's classifies it as codominant between ACSA2 and PODE3
wrong_class <- plot_level %>% filter(PID == '12Mile-1-20')

sum(wrong_class[species])
wrong_class[paste(species, 'rel_TPA', sep = '_')]

wrong_class['ACSA2']/sum(wrong_class[species])
(wrong_class['ACSA2'] + wrong_class['PODE3'])/sum(wrong_class[species])

# This is less than 80% so it should be a mixed forest
wrong_class[paste('ACSA2', 'rel_TPA', sep = '_')] + wrong_class[paste('PODE3', 'rel_TPA', sep = '_')]


comparison %>% filter(type_noah != type_sal)  %>%
  filter(type_noah != 'M')

# Sal classifies this as dominant with ACSA2
# Noah classifies it as codominant between ACSA2 and ULAM
wrong_class_2 <- plot_level %>% filter(PID == '12Mile-1-23')
wrong_class_2
wrong_class_2['ACSA2']/sum(wrong_class_2[species])


wrong_class_2[paste(species, 'rel_TPA', sep = '_')]

# ACSA2 makes up 84% of the trees by count but only 