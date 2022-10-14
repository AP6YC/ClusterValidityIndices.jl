using ClusterValidityIndices    # CVI/ICVI
using AdaptiveResonance         # DDVFA
using MLDatasets                # Iris dataset
using DataFrames                # DataFrames, necessary for MLDatasets.Iris()
using MLDataUtils               # Shuffling and splitting
using Printf                    # Formatted number printing
using Plots                     # Plots frontend
gr()                            # Use the default GR backend explicitly
theme(:dracula)                 # Change the theme for fun

iris = Iris(as_df=false)
features, labels = iris.features, iris.targets

labels = convertlabel(LabelEnc.Indices{Int}, vec(labels))
unique(labels)

# Create a list of two DDVFA modules with different options
arts = [
    DDVFA()                         # Default options
    DDVFA(rho_lb=0.6, rho_ub=0.7)   # Specified options
]
typeof(arts)

# Setup the data configuration for both modules
for art in arts
    data_setup!(art, features)
end

# Create two CVI objects, one for each clustering module
n_cvis = length(arts)
cvis = [CH() for _ = 1:n_cvis]

# Setup the online/streaming clustering
n_samples = length(labels)                  # Number of samples
c_labels = zeros(Int, n_samples, n_cvis)     # Clustering labels for both
criterion_values = zeros(n_samples, n_cvis)  # ICVI outputs

# Iterate over all samples
for ix = 1:n_samples
    # Extract one sample
    sample = features[:, ix]
    # Iterate over all clustering algorithms and CVIs
    for jx = 1:n_cvis
        # Cluster the sample online
        local_label = train!(arts[jx], sample)
        c_labels[ix, jx] = local_label
        # Get the new criterion value (ICVI output)
        criterion_values[ix, jx] = get_cvi!(cvis[jx], sample, local_label)
    end
end

# See the list of criterion values
criterion_values

# Create the plotting function
function plot_icvis(criterion_values)
    p = plot(legend=:topleft)
    for ix = 1:n_cvis
        plot!(
            p,
            1:n_samples,
            criterion_values[:, ix],
            linewidth = 5,
            label = string(typeof(arts[ix])),
            xlabel = "Sample",
            ylabel = "$(typeof(cvis[ix])) Value",
        )
    end
    return p
end

# Show the plot
p = plot_icvis(criterion_values)

png("assets/clustering-comparison") #hide

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

