library(tidyverse)
library(lubridate)


path_of_code <- rprojroot::find_rstudio_root_file()

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
# Otherwise it's classified as mixed
# THis function takes an individual plot as an input
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
  # Will probably need to include 
  s2 <- species[percentage_order[2]]

  # Checks criteria that each individual species must meet to be considered codominant
  s1_crit <- ((percentage[s1] > 0.2) | (plot[paste(s1, 'rel_TPA', sep = '_')] > 0.2))
  s2_crit <- ((percentage[s2] > 0.2) | (plot[paste(s2, 'rel_TPA', sep = '_')] > 0.2))

  if (s1_crit & s2_crit){
    # If both criteria are met, then we check if the total percentage and total TPA 
    # is greater than 80%
    tot_percent <- percentage[s1] + percentage[s2]
    tot_TPA <-plot[paste(s1, 'rel_TPA', sep = '_')] + plot[paste(s2, 'rel_TPA', sep = '_')]

    if ((tot_percent > 0.8) & (tot_TPA > 0.8)){
      output <- paste(s1, s2, 'CD', sep ='_')
      return(output)
    } else {
      # If not, it's mixed
      return('M')
    }
  } else {
    return('M')
  }
}

start <- now()
for (i in 1:nrow(plot_level)){
  plot_level$class[i] <- plot_classifier(plot_level[i, ]) 
  
  if (i %% 250 == 0){
    print(i)
    now() - start
  }
}
end <- now()
end - start

write_csv(plot_level, './clean_data/plot_level_with_class.csv')



