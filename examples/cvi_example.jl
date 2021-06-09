"""
    cvi_example.jl

Description:
    Example usage of an arbitrary CVI/ICVI.

Author:
    Sasha Petrenko <sap625@mst.edu>

Date:
    3/24/2021
"""

# --------------------------------------------------------------------------- #
# PACKAGES
# --------------------------------------------------------------------------- #

# ICVIs pulled from the ClusterValidityIndices package
using ClusterValidityIndices

# Quality of life packages for editing and fancy logging
using ProgressBars
using Logging
using Plots

# --------------------------------------------------------------------------- #
# USER CONFIGURATION
#   The user config, such as data paths and plotting parameters
# --------------------------------------------------------------------------- #

# Select the CVI symbol that you wish to be tested
s_cvi = CH;

# Location of the data
# NOTE: You can switch between the three partitions here
#   To see how every CVI does with every partition, run `src/examples/combined.jl`
data_path = "data/correct_partition.csv"
# data_path = "data/over_partition.csv"
# data_path = "data/under_partition.csv"

# Plotting dots-per-inch
dpi = 300

# Plotting style
theme(:dark)

# Plotting backend
try
    unicodeplots()  # Unicode plots for speed and CI compatibility
catch
    gr()            # GR backend (default for Plots.jl)
end

# --------------------------------------------------------------------------- #
# SCRIPT CONFIGURATION
# --------------------------------------------------------------------------- #

# Set the log level
LogLevel(Logging.Info)

# Load the examples helper functions
include("../test/utils.jl")

# Load the training data
data, labels = get_cvi_data(data_path)
labels = relabel_cvi_data(labels)

# Get the number of samples for incremental iteration
n_samples = length(labels)

# Get the data_name
data_name = splitext(basename(data_path))[1]

# --------------------------------------------------------------------------- #
# INCREMENTAL MODE
#   Run the CVI in incremental mode
# --------------------------------------------------------------------------- #

# Instantiate the icvi with default options
cvi_i = s_cvi()

# Create some storage for our criterion values
criterion_values_i = zeros(n_samples)

# Iterate across all of the samples
for ix = ProgressBar(1:n_samples)
    # Update the CVI internal parameters incrementally
    # NOTE: the package assumes that columns are features and rows are samples
    param_inc!(cvi_i, data[:, ix], labels[ix])
    # Evaluate the CVI to internally store the criterion value
    evaluate!(cvi_i)
    # Extract and save the criterion value at each step
    criterion_values_i[ix] = cvi_i.criterion_value
end

# --------------------------------------------------------------------------- #
# BATCH MODE
#   Run the CVI in batch mode
# --------------------------------------------------------------------------- #

# Instantiate the CVI, same as when done incrementally
cvi_b = s_cvi()

# Compute the parameters in batch
param_batch!(cvi_b, data, labels)

# Evaluate the CVI criterion value
evaluate!(cvi_b)

# NOTE: we only get the last criterion value because we ran in batch mode,
#       which is accessible at cvi_b.criterion_value.

# --------------------------------------------------------------------------- #
# INCREMENTAL MODE: PORCELAIN FUNCTIONS
#   Update and get the CVI at once with the porcelain functions
# --------------------------------------------------------------------------- #

# Instantiate the CVI as both in incremental and batch modes
cvi_p = s_cvi()

# Create storage for the criterion values at each timestep
criterion_values_p = zeros(n_samples)

# Iterate across all samples
for ix = ProgressBar(1:n_samples)
    # Update the CVI parameters and extract the criterion value in one function
    # NOTE: the package assumes that columns are features and rows are samples
    criterion_values_p[ix] = get_icvi!(cvi_p, data[:, ix], labels[ix])
end

# --------------------------------------------------------------------------- #
# VISUALIZATION
# --------------------------------------------------------------------------- #

# Show the last criterion value
@info "Incremental CVI value: $(cvi_i.criterion_value)"
@info "Batch CVI value: $(cvi_b.criterion_value)"
@info "Porcelain Incremental CVI value: $(criterion_values_p[end])"
println("\n")

# Plot the two incremental trends ("manual" and porcelain) atop one another
p = plot(dpi=dpi, legend=:topleft)
plot!(p, 1:n_samples, criterion_values_i, label="Incremental")
plot!(p, 1:n_samples, criterion_values_p, label="Porcelain")
title!("CVI: DB, Data: " * basename(data_path))
xlabel!("Sample Index")
ylabel!("Criterion Value")
xlims!(1, n_samples)
ylims!(0, Inf)

try
    display(p)
    println("\n")
catch
end

# Save the image
# savefig("results/single_" * "_" * data_name)
