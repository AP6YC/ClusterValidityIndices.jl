# ---
# title: ICVI Example
# id: icvi_example
# cover: ../assets/logo.png
# date: 2021-12-6
# author: "[Sasha Petrenko](https://github.com/AP6YC)"
# julia: 1.6
# description: This demo is a simple example of how to use a CVI in batch mode.
# ---

# This demo is a simple example of how to use CVIs incrementally.
# Here, we load a simple dataset and run a basic clustering algorithm to prescribe a set of clusters to the features.
# We will take advantage of the fact that we can compute a criterion value at every step by running the ICVI alongside an online clustering algorithm.
# This simple example demonstrates the usage of a single ICVI, but it may be substituted for any other ICVI in the `ClusterValidityIndices.jl` package.

# ## Clustering

# ### Data Setup

# First, we must load all of our dependencies.
# We will load the `ClusterValidityIndices.jl` along with some data utilities and the Julia `Clustering.jl` package to cluster that data.
using ClusterValidityIndices    # CVI/ICVI
using AdaptiveResonance         # DDVFA
using MLDatasets                # Iris dataset
using MLDataUtils               # Shuffling and splitting
using Printf                    # Formatted number printing

# We will download the Iris dataset for its small size and benchmark use for clustering algorithms.
Iris.download(i_accept_the_terms_of_use=true)
features, labels = Iris.features(), Iris.labels()

# Because the MLDatasets package gives us Iris labels as strings, we will use the `MLDataUtils.convertlabel` method with the `MLLabelUtils.LabelEnc.Indices` type to get a list of integers representing each class:
labels = convertlabel(LabelEnc.Indices{Int}, labels)
unique(labels)

# ### ART Clustering

# Adaptie Resonane Theory (ART) is a neurocognitive theory that is the basis of a class of online clustering algorithms.
# Because these clustering algorithms run online, we can both cluster and compute a new criterion value at every step.
# For more on these ART algorithms, see `AdaptiveResonance.jl`

## Create a Distributed Dual-Vigilance Fuzzy ART (DDVFA) module with default options
art = DDVFA()
