# ---
# title: CVI-ICVI Comparison
# id: cvi_icvi
# cover: ../assets/logo.png
# date: 2022-10-12
# author: "[Sasha Petrenko](https://github.com/AP6YC)"
# julia: 1.8
# description: This demo illustrates how to use incremental training methods vs. batch training for all ART modules. This demo also demonstrates how the final results of each CVI and ICVI are equivalent.
# ---

# ## Overview

# This demo is a simple example of how to use CVIs incrementally and in batch to demonstrate that the end results are the same.
# Here, we load a simple dataset and run a basic clustering algorithm to prescribe a set of clusters to the features.
# In the incremental case, we will take advantage of the fact that we can compute a criterion value at every step by running the ICVI alongside an online clustering algorithm.
# This simple example demonstrates the usage of a single CVI/ICVI, but it may be substituted for any other CVI/ICVI in the `ClusterValidityIndices.jl` package.

# ## Data Setup

# First, we must load all of our dependencies.
# We will load the `ClusterValidityIndices.jl` along with some data utilities and the Julia `Clustering.jl` package to cluster that data.
using ClusterValidityIndices    # CVI/ICVI
using AdaptiveResonance         # DDVFA
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

# ## CVI/ICVI Setup

# Because CVI/ICVIs only differ in their evaluation mode, we will use the same default constructor for both of our objects.
# Here, we will use the same type of CVI for both objects to verify that the results of both are the same at the final iteration.

## Create both CVI objects, using one incrementally as an ICVI
icvi = CH()
cvi = CH()

# ## Online Clustering

# ### Adaptive Resonance Theory Algorithms

# Adaptive Resonance Theory (ART) is a neurocognitive theory that is the basis of a class of online clustering algorithms.
# Because these clustering algorithms run online, we can both cluster and compute a new criterion value at every step.
# For more on these ART algorithms, see [`AdaptiveResonance.jl`](https://github.com/AP6YC/AdaptiveResonance.jl).

## Create a Distributed Dual-Vigilance Fuzzy ART (DDVFA) module with default options
art = DDVFA()
typeof(art)

# Because we are streaming clustering, we must setup the internal data setup of the DDVFA module.
# This is akin to doing some data preprocessing and communicating the dimension of the data, bounds, etc. to the module beforehand.

## Setup the data configuration for the module
data_setup!(art.config, features)
## Verify that the data is setup
art.config.setup

# ### Iteration

# We can now cluster and get the criterion values online
# We will do this by creating an ICVI object, setting up containers for the iterations, and then iterating.

## Setup the online/streaming clustering
n_samples = length(labels)          # Number of samples
c_labels = zeros(Int, n_samples)    # Clustering labels
criterion_values = zeros(n_samples) # ICVI outputs

## Iterate over all samples
for ix = 1:n_samples
    ## Extract one sample
    sample = features[:, ix]
    ## Cluster the sample online
    c_labels[ix] = train!(art, sample)
    ## Get the new criterion value (ICVI output)
    criterion_values[ix] = get_cvi!(icvi, sample, c_labels[ix])
end

## See the list of criterion values
criterion_values

# ## Batch Evaluation

# In batch mode, we will use the sample features and prescribed cluster labels as before to verify that the criterion values are the same at the last iteration.

## Get the final criterion value in batch
batch_criterion_value = get_cvi!(cvi, features, c_labels)

# ## Comparison

# Now we check that the two produce the same results in the end.

## Print the batch result and the final result of the incremental variant
@printf "Batch criterion value: %.4f\n" batch_criterion_value
@printf "Final incremental criterion value: %.4f\n" criterion_values[end]
