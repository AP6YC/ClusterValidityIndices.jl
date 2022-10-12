"""
    runtests.jl

# Description
Entry point for testing the `ClusterValidityIndices.jl` package.
This file wraps the tests in its own `SafeTestsets.jl` test module.

# Authors
- Sasha Petrenko <sap625@mst.edu>
"""

using SafeTestsets

@safetestset "All Test Sets" begin
    include("test_sets.jl")
end # @safetestset "All Test Sets"
