using ClusterValidityIndices
using Test
using Logging

# Set the log level
LogLevel(Logging.Info)

# Include the
include("utils.jl")

@testset "ClusterValidityIndices.jl" begin
    # Run all of the CVI tests
    include("test_cvis.jl")
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
