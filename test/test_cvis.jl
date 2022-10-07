"""
    test_cvis.jl

# Description
A single test set for the testing the functionality of all CVIS modules.

# Authors
- Sasha Petrenko <sap625@mst.edu>
"""

@testset "CVIs" begin
    @info "CVI Testing"

    # Set the approximation CVI tolerance for all comparisons
    tolerance = 1e-1

    # Construct the cvis
    cvis = [
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
    n_cvis = length(cvis)

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
        local_labels = relabel_cvi_data(local_labels)

        # Store the sanitized data
        data[data_path] = local_data
        labels[data_path] = local_labels
        n_samples[data_path] = length(local_labels)
    end

    # Incremental porcelain
    @info "------- ICVI Porcelain -------"
    cvi_ip = Dict()
    for data_path in data_paths
        @info "Data: $data_path"
        cvi_ip[data_path] = deepcopy(cvis)
        for cvi in cvi_ip[data_path]
            for ix = 1:n_samples[data_path]
                sample = data[data_path][:, ix]
                label = labels[data_path][ix]
                _ = get_icvi!(cvi, sample, label)
            end
            @info "CVI: $(typeof(cvi)), index: $(@sprintf("%.12f", cvi.criterion_value))"
        end
    end

    # Batch porcelain
    @info "------- CVI Porcelain -------"
    cvi_bp = Dict()
    for data_path in data_paths
        @info "Data: $data_path"
        cvi_bp[data_path] = deepcopy(cvis)
        # cvs_b = zeros(n_cvis)
        # for cx = 1:n_cvis
        for cvi in cvi_bp[data_path]
            # cvs_b[cx] = get_cvi!(cvi_bp[cx], data, labels)
            # _ = get_cvi!(cvi_bp[data_path][cx], data[data_path], labels[data_path])
            _ = get_cvi!(cvi, data[data_path], labels[data_path])
        end
    end

    # Test that all permutations are equivalent
    for data_path in data_paths
        for cx = 1:n_cvis
            # IP to BP
            @test isapprox(cvi_ip[data_path][cx].criterion_value,
                cvi_bp[data_path][cx].criterion_value,
                atol=tolerance
            )
        end
    end
end
