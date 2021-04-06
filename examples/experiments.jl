"""
    experiments.jl

Description:
    Experiment functions to automate training/testing by other scripts.

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

"""
    test_cvi(cvi::C, data::Array{M, 2}, labels::Array{N, 1}) where {C<:AbstractCVI, M<:Real, N<:Int}

Test the CVI on the data and labels in all configurations (incremental, batch, porcelain).
"""
function test_cvi(cvi::C, data::Array{M, 2}, labels::Array{N, 1}, data_name::String) where {C<:AbstractCVI, M<:Real, N<:Int}
    n_samples = length(labels)

    # ----------------------------------------------------------------------- #
    # INCREMENTAL MODE
    #   Run the CVI in incremental mode
    # ----------------------------------------------------------------------- #

    # Instantiate the icvi with default options
    cvi_i = deepcopy(cvi)

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

    # ----------------------------------------------------------------------- #
    # BATCH MODE
    #   Run the CVI in batch mode
    # ----------------------------------------------------------------------- #

    # Instantiate the CVI, same as when done incrementally
    cvi_b = deepcopy(cvi)

    # Compute the parameters in batch
    param_batch!(cvi_b, data, labels)

    # Evaluate the CVI criterion value
    evaluate!(cvi_b)

    # NOTE: we only get the last criterion value because we ran in batch mode,
    #       which is accessible at cvi_b.criterion_value.

    # ----------------------------------------------------------------------- #
    # INCREMENTAL MODE: PORCELAIN FUNCTIONS
    #   Update and get the ICVI at once with the porcelain functions
    # ----------------------------------------------------------------------- #

    # Instantiate the CVI as both in incremental and batch modes
    cvi_p = deepcopy(cvi)

    # Create storage for the criterion values at each timestep
    criterion_values_p = zeros(n_samples)

    # Iterate across all samples
    for ix = ProgressBar(1:n_samples)
        # Update the CVI parameters and extract the criterion value in one function
        # NOTE: the package assumes that columns are features and rows are samples
        criterion_values_p[ix] = get_icvi!(cvi_p, data[:, ix], labels[ix])
    end

    # ----------------------------------------------------------------------- #
    # BATCH MODE: PORCELAIN FUNCTIONS
    #   Update and get the CVI at once with the porcelain functions
    # ----------------------------------------------------------------------- #

    # Instantiate the CVI as both in incremental and batch modes
    cvi_pb = deepcopy(cvi)

    # Iterate across all samples
    criterion_value_pb = get_cvi!(cvi_pb, data, labels)

    # ----------------------------------------------------------------------- #
    # VISUALIZATION
    # ----------------------------------------------------------------------- #

    # Show the last criterion value
    @info "Incremental CVI value: $(cvi_i.criterion_value)"
    @info "Batch CVI value: $(cvi_b.criterion_value)"
    @info "Porcelain Incremental CVI value: $(criterion_values_p[end])"
    @info "Porcelain Batch CVI value: $(criterion_value_pb)"

    # Plot the two incremental trends ("manual" and porcelain) atop one another
    p = plot(dpi=dpi, reuse=false)
    plot!(p, 1:n_samples, criterion_values_i)
    plot!(p, 1:n_samples, criterion_values_p)
    title!("CVI: " * string(typeof(cvi)) * ", " * data_name)
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
    # savefig("results/single_" * string(typeof(cvi)) * "_" * data_name)

end
