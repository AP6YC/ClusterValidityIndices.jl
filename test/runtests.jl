using ClusterValidityIndices
using Test

include("test_utils.jl")

@testset "ClusterValidityIndices.jl" begin
    # Run all of the CVI tests
    include("test_cvis.jl")
end
