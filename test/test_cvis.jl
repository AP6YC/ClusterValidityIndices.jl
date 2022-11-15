"""
    test_cvis.jl

# Description
A single test set for the testing the functionality of all CVIS modules.

# Authors
- Sasha Petrenko <sap625@mst.edu>
"""

# --------------------------------------------------------------------------- #
# TESTSETS
# --------------------------------------------------------------------------- #

@testset "CVIs" begin
    @info "--- CVI Testing ---"

    # Set the approximation CVI tolerance for all comparisons
    tolerance = 1e-1

    # Grab all the data paths for testing
    data_paths = readdir("data", join=true)

    # Initialize the results data containers
    data, labels, n_samples = Dict(), Dict(), Dict()

    # Sanitize all the data
    p = 1.0

    @info "Subsampling data at rate: $p"
    for data_path in data_paths
        # Load the data, get a subset, and relabel in order
        local_data, local_labels = get_cvi_data(data_path)
        local_data, local_labels = get_bernoulli_subset(local_data, local_labels, p)

        # Store the sanitized data
        data[data_path] = local_data
        labels[data_path] = local_labels
        n_samples[data_path] = length(local_labels)
    end

    @info "--- Testing ScikitLearn Equivalence ---"
    # Try to run the sklearn comparison, skipping everything if an error occurs
    try
        py_sklearn_metrics = pyimport("sklearn.metrics")
        for data_path in data_paths
            cvi = CH()
            criterion_value_j = get_cvi!(cvi, data[data_path], labels[data_path])
            criterion_value_p = (
                py_sklearn_metrics.calinski_harabasz_score(
                    data[data_path]', labels[data_path]
                )
            )
            @test isapprox(criterion_value_j, criterion_value_p)
        end
    # Catch any error from the process
    catch e
        # If the error was a KeyError, then we don't have the CH score from the
        # sklearn version and should skip the entire loop.
        # Otherwise, we should report the error.
        if e !isa(KeyError)
            throw(e)
        end
    end

    # Incremental
    @info "------- Incremental CVI -------"
    cvi_ip = Dict()
    for data_path in data_paths
        @info "Data: $data_path"
        cvi_ip[data_path] = construct_cvis()
        for cvi in cvi_ip[data_path]
            for ix = 1:n_samples[data_path]
                sample = data[data_path][:, ix]
                label = labels[data_path][ix]
                _ = get_cvi!(cvi, sample, label)
            end
            @info "CVI: $(typeof(cvi)), index: $(@sprintf("%.12f", cvi.criterion_value))"
        end
    end

    # Batch
    @info "------- Batch CVI -------"
    cvi_bp = Dict()
    for data_path in data_paths
        @info "Data: $data_path"
        cvi_bp[data_path] = construct_cvis()
        for cvi in cvi_bp[data_path]
            _ = get_cvi!(cvi, data[data_path], labels[data_path])
        end
    end

    # Test that all permutations are equivalent
    for data_path in data_paths
        for cx in eachindex(cvi_ip[data_path])
            # IP to BP
            @test isapprox(cvi_ip[data_path][cx].criterion_value,
                cvi_bp[data_path][cx].criterion_value,
                atol=tolerance
            )
        end
    end
end

@testset "Edge Cases" begin
    @info "--- Testing CVI Edge Cases ---"

    # Test rCIP provided a single sample of any one cluster in batch update
    local_cvi = rCIP()
    local_data = [1 2 3; 4 5 6] / 2
    local_labels = [1, 1, 2]
    _ = get_cvi!(local_cvi, local_data, local_labels)
end
