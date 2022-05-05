using ClusterValidityIndices    # CVI/ICVI
using Clustering                # DBSCAN
using MLDatasets                # Iris dataset
using MLDataUtils               # Shuffling and splitting
using Printf                    # Formatted number printing

Iris.download(i_accept_the_terms_of_use=true)
features, labels = Iris.features(), Iris.labels()

labels = convertlabel(LabelEnc.Indices{Int}, labels)
unique(labels)

results = fuzzy_cmeans(features, 3, 2)

indices = argmax(results.weights, dims=2)

c_labels = vec([c[2] for c in indices])

# Create a CVI object
my_cvi = CH()

# Get the batch criterion value
criterion_value = get_cvi!(my_cvi, features, c_labels)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

