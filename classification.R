library(tidyverse)
library(lubridate)

# in case of changing directory, this will be the directory where
# this file is located.
path_of_code <- rprojroot::find_rstudio_root_file()

# Imports relevant csv files to get the plot level information 
# as well as all the species that we recorded
plot_level <- read_csv('./clean_data/plots.csv')
clean_data <- read_csv('./clean_data/UMRS_FPF_clean.csv')

# Obtains unique species that were observed
species <- clean_data %>% count(TR_SP, sort = T) %>%
  .$TR_SP


# Adds a class column to the plot data frame
# All entries should be NA to start
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
  percentage <- plot[species]/sum(plot[species])
  percentage_order <- order(-percentage)

  # Finds the most abundant species
  s1 <- species[percentage_order[1]]

  # single species dominance check
  if ((percentage[s1] > 0.8) & (plot[paste(s1, 'rel_TPA', sep = '_')] > 0.8)){
    output <- paste(s1, 'D', sep = '_')
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
        output <- paste(s1, s2, 'CD', sep ='_')
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
write_csv(plot_level, './clean_data/plot_level_with_class.csv')

# can see all the unique classes
unique(plot_level$class)

# sorts the classes based on count.  Can see that mixed is the most abundant
# would probably then want to do some sort of clustering algorithm on just the 
# mixed forests since this is such a broad category
plot_level %>% count(class, sort = T)
