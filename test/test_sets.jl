using ClusterValidityIndices
using Test
using Logging
using Printf

# Set the log level
LogLevel(Logging.Info)

# Include the test utilities
include("utils.jl")

@testset "ClusterValidityIndices.jl" begin
    # Run all of the CVI tests
    include("test_cvis.jl")
end

@testset "Utils" begin
    @info "Sorting CVI data"
    # Load the sample data
    data_paths = readdir("../data", join=true)
    local_data, local_labels = get_cvi_data(data_paths[1])
    # Sort the data (reordering both data and labels monotonically)
    local_data, local_labels = sort_cvi_data(local_data, local_labels)
    # Verify that the labels are monotonic iteratively
    is_monotonic = true
    for i = 1:(length(local_labels) - 1)
        if local_labels[i] > local_labels[i + 1]
            is_monotonic = false
        end
    end
    @test is_monotonic
end

@testset "Label Map" begin
    @info "Label Map Testing"

    # Create the ICVI
    cvi = CH()

    # Load the sample data
    data_paths = readdir("../data", join=true)
    local_data, local_labels = get_cvi_data(data_paths[1])

    # Permute the data
    n_data = length(local_labels)
    indices = randperm(n_data)
    local_data = local_data[:, indices]
    local_labels = local_labels[indices]

    # Incrementally compute the ICVI
    for ix in eachindex(local_labels)
        sample = local_data[:, ix]
        label = local_labels[ix]
        _ = get_icvi!(cvi, sample, label)
    end

    @info "Task map: " cvi.label_map
end
