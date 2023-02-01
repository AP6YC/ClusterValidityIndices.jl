using
    ClusterValidityIndices,     # CVI/ICVI
    AdaptiveResonance,          # DDVFA
    MLDatasets,                 # Iris dataset
    DataFrames,                 # DataFrames, necessary for MLDatasets.Iris()
    MLDataUtils,                # Shuffling and splitting
    Printf,                     # Formatted number printing
    Plots                       # Plots frontend
gr()                            # Use the default GR backend explicitly
theme(:dracula)                 # Change the theme for fun

iris = Iris(as_df=false)
features, labels = iris.features, iris.targets

labels = convertlabel(LabelEnc.Indices{Int}, vec(labels))
unique(labels)

# Create a Distributed Dual-Vigilance Fuzzy ART (DDVFA) module with default options
art = DDVFA()
typeof(art)

# Setup the data configuration for the module
data_setup!(art, features)
# Verify that the data is setup
art.config.setup

# Create an ICVI object
icvi = CH()

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

# Create the plotting object
p = plot(
    1:n_samples,
    criterion_values,
    linewidth = 5,
    title = "Incremental $(typeof(icvi)) Index",
    xlabel = "Sample",
    ylabel = "$(typeof(icvi)) Value",
)

png("assets/icvi-example") #hide

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

