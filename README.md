# UWL-REU-FPF
A repository for the University of Wisconsin, La Crosse Summer REU 2020 Floodplain Forest group.

This repo holds all of the work that we did over the summer to develop our classification system for the Upper Mississippi River Floodplain Forests using CAP functions and Ward's clustering method. The R scripts are split into two folders - "Essential Scripts," where the scripts actually used for investigation and to develop our classification system are held, and "Nonessentials and Failed Tests," where the scripts that were not used to develop the final classification system and associated analyses are contained.

Here are the general datasets that we created as intermediaries for the project:
1. Full cleaned data set: "UMRS_FPF_clean.csv" - produced by "forest_inventory_cleaning.R", this is the fully cleaned and merged original data.
2. Unclean data: "Unclean_combined.csv" - produced "unclean_data_join.R", it is the unclean data .csv files merged together
3. "classified_plots_labels_with_mixed.csv" - produced by hand by adding mixed to "classified_plots_labels" which is output by Level 1 scripts (they are also known as "labels" in many scripts)
4. "names.csv" - produced by hand, contains the level 2 classification names mapped to the cluster numbers and level 1 classes
5. "FINAL_plots_summary" - produced by "big_table.R," contains the final classes for each plot, along with some useful summary statistics.
6. "FINAL_types_summary" - produced by "big_table.R," contains the final list of level 2 classes and some summary statistics about them.


Here is the index, or description of the function for each essential R script:
1. Cleaning scripts
a. DATA CLEANING: "forest_inventory_cleaning.R" holds the script that produces a cleaned dataset from the uncleaned data. It relies on having the original datasets in their original format.
b. UNCLEAN MERGING: "unclean_data_join" creates a file containing all of the uncleaned forest data in just one .csv file. It relies on having the original datasets in their original format.
2. Exploration scripts
a. EXPLORATION: "initial questions.Rmd" holds the answers to all of the initial questions about the dataset, before we started making our classification system. This relies on the full cleaned data set.
b. ADDITIONAL EXPLORATION: "additional_exploration.Rmd" holds the answers to some more complex questions about the dataset that were added soon afer the project started. This relies on the full cleaned data set.
3. LEVEL 1 CLASSIFICATION: "Level_1.R" creates the level 1 classification and produces some basic graphs about them, including a Principal Component Analysis. This relies on the full cleaned data set. 
4. TESTS FOR LEVEL 2: "level2_classification" provides our tests for potential clustering methods, including alternates as well as the final choice, Ward's method. This relies on having the dissimilarity matrix for the level 1 class you want to test.
5. LEVEL 2 PROCEDURE: "classification_procedure_cluster.R" contains functions to load the data, produce dissimilarity matrix, and find the best clustering solution. Uncommenting the final lines allows for a file output of the level 2 classification named "classified_plots_full.csv" and "classified_plots_labels.csv." NOTE that mixed plots are added manually. This relies on "plot_classification.csv" which is produced from Level_1.R and the full cleaned data.
6. LEVEL 2 CLASSES: "classification_summary.R" produces the CAP plots that were visually analyzed to obtain the level 2 class names. It also includes a number of other graphs that were included in the final report. This relies on "plot_classification.csv" which is produced from Level_1.R and the full cleaned data.
7. Final analyses
a. FINAL SUMMARY STATISTICS: "big_table.R" is used to produce summary statistics about the final classification system. Relies on the labels of the level 1 class, the names of the level 2 classes, and the cleaned data.
b. MAP: "mapping.R" produces a rudimentary map and can be edited for your desired stand; uses the geographic data, which was added to our original data set later.

BONUS 1: "Species_dictionary.R" provides a useful tool for mapping species codes to names

BONUS 2: "dissim.R" contains just the code needed to construct a dissimilarity matrix for the level 2 classification.

BONUS 3: "ward_examination.R" produces an investigation of the Ward method for clustering as well as a principal component analysis.
