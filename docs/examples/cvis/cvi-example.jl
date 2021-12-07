# ---
# title: CVI Example
# id: cvi_example
# cover: ../assets/logo.png
# date: 2021-12-6
# author: "[Sasha Petrenko](https://github.com/AP6YC)"
# julia: 1.6
# description: This demo is a simple example of how to use a CVI in batch mode.
# ---

using ClusterValidityIndices    # CVI/ICVI
using Clustering                # DBSCAN
using MLDatasets                # Iris dataset
using MLDataUtils               # Shuffling and splitting
using Printf                    # Formatted number printing


# We will download the Iris dataset for its small size and benchmark use for clustering algorithms.
Iris.download(i_accept_the_terms_of_use=true)
features, labels = Iris.features(), Iris.labels()

# Because the MLDatasets package gives us Iris labels as strings, we will use the `MLDataUtils.convertlabel` method with the `MLLabelUtils.LabelEnc.Indices` type to get a list of integers representing each class:
labels = convertlabel(LabelEnc.Indices{Int}, labels)
unique(labels)

results = fuzzy_cmeans(features, 3, 2)
# Show the result weights
results.weights
# Find the maximum elements
indices = argmax(results.weights, dims=2)

# asdf
c_labels = [c[2] for c in indices]
# indices[2]