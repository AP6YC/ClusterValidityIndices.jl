using ClusterValidityIndices    # CVI/ICVI
using AdaptiveResonance         # DDVFA
using MLDatasets                # Iris dataset
using MLDataUtils               # Shuffling and splitting
using Printf                    # Formatted number printing
using Plots

Iris.download(i_accept_the_terms_of_use=true)
features, labels = Iris.features(), Iris.labels()

labels = convertlabel(LabelEnc.Indices{Int}, labels)
unique(labels)

# Create a Distributed Dual-Vigilance Fuzzy ART (DDVFA) module with default options
art = DDVFA()
typeof(art)

# Setup the data configuration for the module
data_setup!(art.config, features)
# Verify that the data is setup
art.config.setup

# Create many ICVI objects
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

# Setup the online/streaming clustering
n_samples = length(labels)          # Number of samples
n_icvi = length(icvis)              # Number of ICVIs being computed
c_labels = zeros(Int, n_samples)    # Clustering labels
criterion_values = zeros(n_icvi, n_samples) # ICVI outputs

# Iterate over all samples
for ix = 1:n_samples
    # Extract one sample
    sample = features[:, ix]
    # Cluster the sample online
    c_labels[ix] = train!(art, sample)
    # Get the new criterion values (ICVI output)
    for jx = 1:n_icvi
        criterion_values[jx, ix] = get_icvi!(icvis[jx], sample, c_labels[ix])
    end
end

# See the matrix of criterion values
criterion_values

criterion_values[:, end]

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

