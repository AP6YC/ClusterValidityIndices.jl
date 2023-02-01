using
    ClusterValidityIndices,     # CVI/ICVI
    AdaptiveResonance,          # DDVFA
    MLDatasets,                 # Iris dataset
    DataFrames,                 # DataFrames, necessary for MLDatasets.Iris()
    MLDataUtils,                # Shuffling and splitting
    Printf                      # Formatted number printing

iris = Iris(as_df=false)
features, labels = iris.features, iris.targets

labels = convertlabel(LabelEnc.Indices{Int}, vec(labels))
unique(labels)

# Create both CVI objects, using one incrementally as an ICVI
icvi = CH()
cvi = CH()

# Create a Distributed Dual-Vigilance Fuzzy ART (DDVFA) module with default options
art = DDVFA()
typeof(art)

# Setup the data configuration for the module
data_setup!(art.config, features)
# Verify that the data is setup
art.config.setup

# Setup the online/streaming clustering
n_samples = length(labels)          # Number of samples
c_labels = zeros(Int, n_samples)    # Clustering labels
criterion_values = zeros(n_samples) # ICVI outputs

# Iterate over all samples
for ix = 1:n_samples
    # Extract one sample
    sample = features[:, ix]
    # Cluster the sample online
    c_labels[ix] = train!(art, sample)
    # Get the new criterion value (ICVI output)
    criterion_values[ix] = get_cvi!(icvi, sample, c_labels[ix])
end

# See the list of criterion values
criterion_values

# Get the final criterion value in batch
batch_criterion_value = get_cvi!(cvi, features, c_labels)

# Print the batch result and the final result of the incremental variant
@printf "Batch criterion value: %.4f\n" batch_criterion_value
@printf "Final incremental criterion value: %.4f\n" criterion_values[end]

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

