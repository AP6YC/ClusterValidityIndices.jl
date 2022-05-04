# Background

This page provides a theoretical overview of cluster validity indices and what this project aims to accomplish.

## Problem Statement

Consider the following: say that you have an unlabeled dataset filled with vectors of features but no predefined "bins" that you could organize these sampels into.
The desired end result is both a statement of how many bins of samples you have and a vector of labels corresponding to each sample prescribing which bin that sample belongs to.
Both of these statements are generally equivalent beyond some edge cases, but it is worth noting the distinction.

In this case, the realms of machine learning and statistics have the answer for you: clustering!
So you do your research, select a suitable clustering algorithm for your dataset, program the algorithm, and retrieve a set of labels/bins for your dataset.
What you've done is no small feat, built as it is upon the shoulders of giants.
However, here comes the rub: how do you know how good your resulting bins are?
Do these categories accurately reflect some underlying structure to the data, or are they no better than choosing random labels for each sample?

Your first test may be to use another clustering algorithm, and then another.
It is wise to check your answer against multiple other clustering algorithms because you don't want to put all of your eggs in one basket; though all clustering algorithms have different formulations that might give different results, they should all converge to the same sort of answer if the answer is correct in any way, shouldn't they?
Sometimes they do, but usually they don't; different ways of binning things together result in different biases of structure.

If the algorithms all give different answers, then which one is correct?
If they're all different, can any one of them even be considered correct in the first place?
The answer, sadly, is no.
**By definition, we cannot know if our answer is correct if we do not have the "true" labels for the data, if they even exist in the first place.**

Since we can't create a true performance metric to compare how our clustering algorithms do on our dataset, we must find a way to create metrics that somehow give us a number based upon the structural behavior of the clustering algorithm.
Enter cluster validity indices.

## What are Cluster Validity Indices?

Cluster Validity Indices (CVIs) are metrics designed to tackle the problem of creating a metric of performance for unsupervised algorithms where the true answer is unknown.
Clustering is a ubiquitous unsupervised learning paradigm, so the terminology and development of CVIs principally targets clustering algorithms.

Because the clustering problem statement means that we do not have truth labels to measure how well or poorly these algorithms perform, the most that we can do is to create a metric of the **validity** of the solution.
This typically translates to how much an algorithm over- or under-partitions the data (i.e., how eager or reticent it is to create new categories), but some CVIs take other aspects of the structure of the solution into account, such as **compactness** (i.e., the density of the prescribed cluster regions) and **connectedness** (i.e., a measure of how much disparate points in a cluster can be said to still belong to the same category).

In general, CVIs take a set of samples and the labels prescribed to them by a clustering algorithm, and they return a **criterion value** that is a positive real number.
This criterion value generally does not have an upper bound, and it changes as new samples are labeled and the CVI is reprocessed.
In fact, it is the trendlines of these values that provide the most information about the clustering process rather than the values themselves.

CVIs are originally derived to work on batches of samples and labels.
However, there exist incremental variants that are proven to be mathematically equivalent to their batch counterparts.
Incremental CVIs (ICVIs) mitigates the computational overhead of computing these metrics online, such as in a streaming clustering scenario.
