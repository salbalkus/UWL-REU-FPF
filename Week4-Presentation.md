Floodplain Forest: Week 4 Progress Report
========================================================
author: Sal Balkus, Noah Dean, Makayla McDevitt
date: 6/26/20
autosize: true
css: Week2-Presentation.css
type: section



Our Current Objective
========================================================
left: 70%

To construct a hierarchical classification of UMRS forest types that are...
- Ecologically unique
- Useful to foresters
- Suitable for scientific research

<b>Last week</b>, we completed Level 1 using simple rules-based classification and examined various clustering algorithms.

<b>This week</b>, we construct a function for Level 2 classification and visualize results.

***
<img src="Week3-Presentation-figure/unnamed-chunk-18-1.png" height = 100%></img>



Summary statistics from last week
========================================================
Dominant plots: 17.5 percent; codominant plots: 34.3 percent

<img src="Week4-Presentation-figure/unnamed-chunk-2-1.png" title="plot of chunk unnamed-chunk-2" alt="plot of chunk unnamed-chunk-2" width="50%" /><img src="Week4-Presentation-figure/unnamed-chunk-2-2.png" title="plot of chunk unnamed-chunk-2" alt="plot of chunk unnamed-chunk-2" width="50%" />





Exploration of Ward's Clustering Method
========================================================

How can we define these clusters in a simpler manner?

How can we select the correct number of clusters to use in our definition?

How can we ensure our clusters are ecologically significant?

***

![plot of chunk unnamed-chunk-3](Week4-Presentation-figure/unnamed-chunk-3-1.png)

Ward's Method with Three Clusters, Silver Maple



Simplifying Clusters: Rule Extraction
========================================================
De Caceres et al (2019) recommends supervised learning for assignment rules to define clusters.

<b>Decision Trees</b> can extract rules to define clusters in a simpler manner
- Input clusters as labels for training data
- Partitions feature space based on simple logic-based rules (greater than or less than)
- Can inform on the number of clusters to use by comparing to clustering


Decision Tree versus Ward's Method
========================================================
<img src="Week4-Presentation-figure/unnamed-chunk-4-1.png" title="plot of chunk unnamed-chunk-4" alt="plot of chunk unnamed-chunk-4" width="33%" /><img src="Week4-Presentation-figure/unnamed-chunk-4-2.png" title="plot of chunk unnamed-chunk-4" alt="plot of chunk unnamed-chunk-4" width="33%" /><img src="Week4-Presentation-figure/unnamed-chunk-4-3.png" title="plot of chunk unnamed-chunk-4" alt="plot of chunk unnamed-chunk-4" width="33%" />

Finding the Correct Number of Clusters
========================================================
Take decision tree classification most similar to  Ward clustering, determined by v-measure

V-measure takes into account homogeneity and completeness (entropy-based)

<div align = "center">
<img src="week_4_pres_images/v-measure.png" width = 40%></img><br>
<img src="week_4_pres_images/homogeneity.png" width = 40%></img>
<img src="week_4_pres_images/completeness.png" width = 40%></img>
</div>

***
![plot of chunk unnamed-chunk-5](Week4-Presentation-figure/unnamed-chunk-5-1.png)



Results: Green Ash
========================================================

<img src="Week4-Presentation-figure/unnamed-chunk-6-1.png" title="plot of chunk unnamed-chunk-6" alt="plot of chunk unnamed-chunk-6" width="49%" /><img src="Week4-Presentation-figure/unnamed-chunk-6-2.png" title="plot of chunk unnamed-chunk-6" alt="plot of chunk unnamed-chunk-6" width="49%" />

Further Issues to Investigate in Dominant Plots
========================================================
Imbalanced Class Problem
- Some clusters may have few plots but are ecologically significant
- Potential Solution: oversample classes such that they have the same number of observations as largest class
  - Issue: can result in poor performance, as in Green Ash and Willow clusterings
  
Further Issues to Investigate in Dominant Plots
========================================================
Ecological Significance
- How can we determine if clusters are too similar?
- Potential Solution: "Multi Response Permutation Procedure" or "Permutational Multivariate Analysis of Variance"    
  - Tests for significant differences between clusters
  - How can we pick out which clusters to merge?

Minimum bin size has large impact on decision tree solution




Mixed Plots
========================================================



- Summary information:
 - 8225 mixed plots 
 - 43.39% of plots
 
- Plots can have significant variation in size and species distributions

- Provides a challenge in clustering plots
  - Which differences are ecologically important?


First steps
===========
left: 50%

- Use CAP values for hierarchical clustering on the mixed plots

- Cut dendrogram, examine cluster composition

  - Species composition and the size structures within clusters

***

<img src="Week4-Presentation-figure/unnamed-chunk-8-1.png" title="plot of chunk unnamed-chunk-8" alt="plot of chunk unnamed-chunk-8" width="90%" style="display: block; margin: auto;" />

The Lone Plot 
====
left: 40% 


- Plot `TDB` is lone cluster at k = 3

- Silver maple prominent in both clusters 1 and 2

- `TBD` has higher amounts of snags and sycamores than the two clusters
  - As well as swamp privet

***
<center><b>Proportion of common species in each category (count, trees per acre, and basal area)</b></center>

<img src="Week4-Presentation-figure/unnamed-chunk-9-1.png" title="plot of chunk unnamed-chunk-9" alt="plot of chunk unnamed-chunk-9" width="90%" style="display: block; margin: auto;" />

The Lone Plot 
====

<center><b>Proportion of species in each category (count, trees per acre, and basal area)</b></center>

<img src="Week4-Presentation-figure/unnamed-chunk-10-1.png" title="plot of chunk unnamed-chunk-10" alt="plot of chunk unnamed-chunk-10" width="62%" style="display: block; margin: auto;" />


Taking more clusters
======
right: 50%

<center><b>Proportion of common species in each category (count, trees per acre, and basal area)</b></center>
<img src="Week4-Presentation-figure/unnamed-chunk-11-1.png" title="plot of chunk unnamed-chunk-11" alt="plot of chunk unnamed-chunk-11" width="90%" style="display: block; margin: auto;" />

***
- Must determine # of clusters while retaining ecological relevance
- Examine species and size distributions
- 8 and 9, 1 and 6 similar in structure
- Must quantify differences between clusters
  - Could potentially use CAPs of clusters


Comparing CAPs among clusters
======

<img src="Week4-Presentation-figure/unnamed-chunk-12-1.png" title="plot of chunk unnamed-chunk-12" alt="plot of chunk unnamed-chunk-12" width="62%" style="display: block; margin: auto;" />

Next steps for the mixed plots
======
- Determine the best clusters for these plots

- Exact methods will be discussed next week
  - Possibly multidimensional scaling
  - May need to subsample due to long run time
  
- As for dominant, decision trees can extract rules for each cluster

========================================================
<center><img src="week_4_pres_images/title.png" width=50%></center>

Ordination: summarizes multidimensional data by plotting similar species and samples close together in low-dimensional ordination space

- Useful for visualizing cluster solutions 


Goal for nMDS plot, from https://jonlefcheck.net/ 
========================================================
<img src="week_4_pres_images/plot_example.png" width=50% height=50%>



Other Ordination Methods
========================================================
Alternate Methods: Principal components analysis (PCA), Principal coordinate analysis (PCoA) (graphic from https://ourcodingclub.github.io/)

<img src="week_4_pres_images/pcoa.png" width=100% height=50%>

***

- Analytical approaches: single unique solutions 
- Use techniques based on eigenvalues and eigenvectors 
- Assume linear or model relationships within data 


nMDS  
========================================================
- Numerical, iterative approach: no unique solution

  - Stops when acceptable solution is obtained or after set number of attempts 

- More configuration options

- Fewer assumptions 


Drawbacks:

- Slow 
- sometimes finds local minimum instead of best solution 

Computation: nMDS process 
========================================================
- Calculates a distance matrix from an original matrix of samples and variables 
- Chooses m dimensions for ordination
- nMDS software begins with initial configuration of samples in those m dimensions
- Calculates distances among samples
- Regresses distances against original distance matrix
- Calculates predicted ordination distances for each pair of samples



Computation: quality of fit
========================================================
- Sum of squared differences between ordination-based distances and distances predicted by regression
- Kruskal’s stress equation
  - D_hi: ordinated distance between samples h and i 
	- D-hat: distance predicted from regression
	
<img src="week_4_pres_images/stress_equation.png" width=100% height=75%>


Computation: fit improvement 
========================================================
- Slightly alters positions of samples based on stress value 
- Recalculates ordination distance matrix and stress value
- Repeats until procedure converges or for set number of iterations 

Considerations  
========================================================

Concern: too many or too few dimensions

Solution: Scree Diagram 

nMDS on Willow, maximum number of iterations = 500

<img src="week_4_pres_images/stress.png" width=50% height=50%>


Current Plot vs. Goal   
========================================================

<img src="week_4_pres_images/plot.png" width=100% height=100%>

*** 
<img src="week_4_pres_images/plot_example.png" width=70% height=70%>

Endnotes
===========

Cover Image: Forest Landscape Ecology of the Upper Mississippi River Floodplain, United States Geological Survey

V-measure: http://www1.cs.columbia.edu/~amaxwell/pubs/v_measure-emnlp07.pdf

NMDS: https://strata.uga.edu/software/pdf/mdsTutorial.pdf
