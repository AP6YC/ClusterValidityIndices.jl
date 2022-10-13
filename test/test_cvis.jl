"""
    test_cvis.jl

# Description
A single test set for the testing the functionality of all CVIS modules.

# Authors
- Sasha Petrenko <sap625@mst.edu>
"""

"""
Constructs and returns a list of all cvis
"""
function construct_cvis()
    # Construct the cvis as a list
    cvis = [local_cvi() for local_cvi in CVI_MODULES]

    # Return a list of constructed CVIs
    return cvis
end

@testset "CVIs" begin
    @info "CVI Testing"

    # Set the approximation CVI tolerance for all comparisons
    tolerance = 1e-1

    # Grab all the data paths for testing
    data_paths = readdir("../data", join=true)

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
    @info "Testing CVI Edge Cases"

    # Test rCIP provided a single sample of any one cluster in batch update
    local_cvi = rCIP()
    local_data = [1 2 3; 4 5 6] / 2
    local_labels = [1, 1, 2]
    _ = get_cvi!(local_cvi, local_data, local_labels)
end
