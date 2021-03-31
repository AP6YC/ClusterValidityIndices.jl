using ClusterValidityIndices
using Test

include("test_utils.jl")

@testset "ClusterValidityIndices.jl" begin
    # Write your tests here.
    include("test_cvis.jl")
end
