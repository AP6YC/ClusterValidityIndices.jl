# ---
# title: Multi-ICVI Comparisons
# id: icvi_comparison
# cover: ../assets/logo.png
# date: 2021-12-7
# author: "[Sasha Petrenko](https://github.com/AP6YC)"
# julia: 1.6
# description: This demo illustrates the differing behavior of each ICVI.
# ---

# ## Overview

# This demo demostrates the differing behavior of the various ICVIs implemented in `ClusterValidityIndices.jl`.
# Here, we load a simple dataset and run a basic clustering algorithm to prescribe a set of clusters to the features.
# We will take advantage of the fact that we can compute a criterion value at every step by running the ICVI alongside an online clustering algorithm.

# ## Online Clustering

# ### Data Setup

# First, we must load all of our dependencies.
# We will load the `ClusterValidityIndices.jl` along with some data utilities and the Julia `Clustering.jl` package to cluster that data.
using ClusterValidityIndices    # CVI/ICVI
using AdaptiveResonance         # DDVFA
using MLDatasets                # Iris dataset
using MLDataUtils               # Shuffling and splitting
using Printf                    # Formatted number printing
using Plots

# We will download the Iris dataset for its small size and benchmark use for clustering algorithms.
Iris.download(i_accept_the_terms_of_use=true)
features, labels = Iris.features(), Iris.labels()

# Because the MLDatasets package gives us Iris labels as strings, we will use the `MLDataUtils.convertlabel` method with the `MLLabelUtils.LabelEnc.Indices` type to get a list of integers representing each class:
labels = convertlabel(LabelEnc.Indices{Int}, labels)
unique(labels)

# ### ART Online Clustering

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

# We can now cluster and get the criterion values online.
# We will do this by creating many ICVI objects, setting up containers for the iterations, and then iterating.

## Create many ICVI objects
icvis = [
    CH(),
    cSIL(),
    DB(),
    GD43(),
    GD53(),
    PS(),
    rCIP(),
    WB(),
    XB(),
]

## Setup the online/streaming clustering
n_samples = length(labels)          # Number of samples
n_icvi = length(icvis)              # Number of ICVIs being computed
c_labels = zeros(Int, n_samples)    # Clustering labels
criterion_values = zeros(n_icvi, n_samples) # ICVI outputs

## Iterate over all samples
for ix = 1:n_samples
    ## Extract one sample
    sample = features[:, ix]
    ## Cluster the sample online
    c_labels[ix] = train!(art, sample)
    ## Get the new criterion values (ICVI output)
    for jx = 1:n_icvi
        criterion_values[jx, ix] = get_icvi!(icvis[jx], sample, c_labels[ix])
    end
end

## See the matrix of criterion values
criterion_values

# We can inspect the final ICVI values to see how they differ:
criterion_values[:, end]


x = range(0, stop=6π, length=1000)
y1 = sin.(x)
y2 = cos.(x)
plot(x, [y1, y2])
