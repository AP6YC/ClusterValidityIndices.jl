# ---
# title: CVI Simple Example
# id: cvi_example
# cover: ../assets/logo.png
# date: 2021-12-6
# author: "[Sasha Petrenko](https://github.com/AP6YC)"
# julia: 1.6
# description: This demo is a simple example of how to use a CVI in batch mode.
# ---

# ## Overview

# This demo is a simple example of how to use CVIs in batch mode.
# Here, we load a simple dataset and run a basic clustering algorithm to prescribe a set of clusters to the features.
# It is a combination of these features and the prescribed labels that are used to compute the criterion value.
# This simple example demonstrates the usage of a single CVI, but it may be substituted for any other CVI in the `ClusterValidityIndices.jl` package.

# ## Clustering

# ### Data Setup

# First, we must load all of our dependencies.
# We will load the `ClusterValidityIndices.jl` along with some data utilities and the Julia `Clustering.jl` package to cluster that data.
using ClusterValidityIndices    # CVI/ICVI
using Clustering                # DBSCAN
using MLDatasets                # Iris dataset
using DataFrames                # DataFrames, necessary for MLDatasets.Iris()
using MLDataUtils               # Shuffling and splitting
using Printf                    # Formatted number printing

# We will download the Iris dataset for its small size and benchmark use for clustering algorithms.
iris = Iris(as_df=false)
features, labels = iris.features, iris.targets

# Because the MLDatasets package gives us Iris labels as strings, we will use the `MLDataUtils.convertlabel` method with the `MLLabelUtils.LabelEnc.Indices` type to get a list of integers representing each class:}
labels = convertlabel(LabelEnc.Indices{Int}, vec(labels))
unique(labels)

# ### Fuzzy C-Means

# Get the Fuzzy C-Means clustering result
results = fuzzy_cmeans(features, 3, 2)

# Because the results are fuzzy weights, find the maximum elements along each sample
indices = argmax(results.weights, dims=2)

# Get those labels as a vector of integers
c_labels = vec([c[2] for c in indices])

# ## CVI Criterion Value Extraction

# Now that we have some data and a clustering algorithm's prescribed labels, we can compute a criterion value using a CVI in batch mode.
# First, we create a CVI object with the default constructor:

## Create a CVI object
my_cvi = CH()

# Finally we can simply get the criterion value in batch by passing all of the data and Fuzzy C-Means labels at once.

## Get the batch criterion value
criterion_value = get_cvi!(my_cvi, features, c_labels)
