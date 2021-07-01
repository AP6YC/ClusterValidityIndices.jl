using ClusterValidityIndices
using Test
using Logging

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

@testset "Example Scripts" begin
    # Switch to the top for execution because our scripts point to the datasets
    # relative to themselves, not relative to the test dir
    @info "Test directory" pwd()
    cd("../")
    @info "Switching working directory to top for running scripts" pwd()

    # Run scripts
    include("../examples/cvi_example.jl")
end
