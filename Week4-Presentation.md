<<<<<<< HEAD
Week4-Presentation
=======
Floodplain Forest: Week 4 Progress Report
>>>>>>> f389da0becee90a750e5f3820f7d80beeb9b1b13
========================================================
author: Sal Balkus, Noah Dean, Makayla McDevitt
date: 6/26/20
autosize: true
css: Week2-Presentation.css
<<<<<<< HEAD

Decision Trees
========================================================

For more details on authoring R presentations please visit <https://support.rstudio.com/hc/en-us/articles/200486468>.

- Bullet 1
- Bullet 2
- Bullet 3
=======
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



Summary statistics from last week: Top 5 Types
========================================================

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
Take the decision tree classification most similar to the Ward clustering, determined by v-measure

V-measure takes into account cluster homogeneity and completeness, which rely on entropy

<div align = "center">
<img src="Week4-Presentation-figure/v-measure.png" width = 40%></img><br>
<img src="Week4-Presentation-figure/homogeneity.png" width = 40%></img>
<img src="Week4-Presentation-figure/completeness.png" width = 40%></img>
</div>

***
![plot of chunk unnamed-chunk-5](Week4-Presentation-figure/unnamed-chunk-5-1.png)



Results: Green Ash
========================================================

<img src="Week4-Presentation-figure/unnamed-chunk-6-1.png" title="plot of chunk unnamed-chunk-6" alt="plot of chunk unnamed-chunk-6" width="49%" /><img src="Week4-Presentation-figure/unnamed-chunk-6-2.png" title="plot of chunk unnamed-chunk-6" alt="plot of chunk unnamed-chunk-6" width="49%" />

Further Issues to Investigate
========================================================
Imbalanced Class Problem
- Some clusters may have few plots but are ecologically significant
- Potential Solution: oversample classes such that they have the same number of observations as largest class
  - Issue: can result in poor performance, as in Green Ash and Willow clusterings
  
Further Issues to Investigate
========================================================
Ecological Significance
- How can we determine if clusters are two similar?
- Potential Solution: "Multi Response Permutation Procedure" or "Permutational Multivariate Analysis of Variance"    
  - Tests for significant differences between clusters
  - How can we pick out which clusters to merge?

Minimum bin size has large impact on decision tree solution

>>>>>>> f389da0becee90a750e5f3820f7d80beeb9b1b13

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
left: 25%

- Use CAP values to perform a hierarchical clustering on the mixed plots

- Cut the dendrogram and look at the composition of clusters

  - Take cursory glances at species composition and the size structures within clusters

***

<<<<<<< HEAD
<img src="Week4-Presentation-figure/unnamed-chunk-2-1.png" title="plot of chunk unnamed-chunk-2" alt="plot of chunk unnamed-chunk-2" width="90%" style="display: block; margin: auto;" />
=======
<img src="Week4-Presentation-figure/unnamed-chunk-8-1.png" title="plot of chunk unnamed-chunk-8" alt="plot of chunk unnamed-chunk-8" width="90%" style="display: block; margin: auto;" />
>>>>>>> f389da0becee90a750e5f3820f7d80beeb9b1b13

The Lone Plot 
====
left: 25% 


- The plot `TDB` is in a cluster by itself when k = 3

- Silver maple is prominent in both clusters 1 and 2

- `TBD` has higher amounts of snags and sycamores than the two clusters

***
<center> <font size = '20'> Proportion of common species in each category (count, trees per acre, and basal area) </font> </center>

<<<<<<< HEAD
<img src="Week4-Presentation-figure/unnamed-chunk-3-1.png" title="plot of chunk unnamed-chunk-3" alt="plot of chunk unnamed-chunk-3" width="80%" style="display: block; margin: auto;" />

The Lone Plot 
====

<center> <font size = '24'> Proportion of species in each category (count, trees per acre, and basal area) </font> </center>

<img src="Week4-Presentation-figure/unnamed-chunk-4-1.png" title="plot of chunk unnamed-chunk-4" alt="plot of chunk unnamed-chunk-4" width="62%" style="display: block; margin: auto;" />


Taking more clusters
======
right: 25%

<center> <font size = '20'> Proportion of common species in each category (count, trees per acre, and basal area) </font> </center>

<img src="Week4-Presentation-figure/unnamed-chunk-5-1.png" title="plot of chunk unnamed-chunk-5" alt="plot of chunk unnamed-chunk-5" width="80%" style="display: block; margin: auto;" />

***
- We need to determine the correct amount clusters to make while still retaining ecological relevance

- Requires looking at the species and size distributions of the plots

- Some of the plots look similar in structure
  - 8 and 9
  - 1 and 6
  
- Need a good way to quantify the differences between clusters
  - Could potentially use CAPs of the clusters


Comparing CAPs among clusters
======

<img src="Week4-Presentation-figure/unnamed-chunk-6-1.png" title="plot of chunk unnamed-chunk-6" alt="plot of chunk unnamed-chunk-6" width="62%" style="display: block; margin: auto;" />

Next steps for the mixed plots
======
- Determine the best clusters for these plots

- Exact methods for this will be discussed next week
  - Possibly multidimensional scaling
  - May need to sub sample due to long run time
  
- Once clusters are picked out, we can use decision trees to find the rules for each cluster



Non-metric Multidimensional Scaling
========================================================

![plot of chunk unnamed-chunk-7](Week4-Presentation-figure/unnamed-chunk-7-1.png)
=======









```
Error in loadNamespace(name) : there is no package called 'ggpubr'
```
>>>>>>> f389da0becee90a750e5f3820f7d80beeb9b1b13
