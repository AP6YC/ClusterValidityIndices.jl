"""
    test_sets.jl

# Description
Aggregate of all test sets for the `ClusterValidityIndices.jl` package.
These tests include testing package functionality as well as individual CVI module functionality.

# Authors
- Sasha Petrenko <sap625@mst.edu>
"""

# --------------------------------------------------------------------------- #
# USINGS
# --------------------------------------------------------------------------- #

using
    ClusterValidityIndices,
    Conda,
    Test,
    Logging,
    Printf,
    PyCall

# --------------------------------------------------------------------------- #
# SETUP
# --------------------------------------------------------------------------- #

# If sklearn loading fails from the default install, explicitly install internally
try
    _ = pyimport("sklearn.metrics")
catch
    ENV["PYTHON"] = ""
    Conda.add("scikit-learn")
end

# Set the log level
LogLevel(Logging.Info)

# Include the test utilities
include("utils.jl")

# --------------------------------------------------------------------------- #
# TEST SETS
# --------------------------------------------------------------------------- #

@testset "ClusterValidityIndices.jl" begin
    # Run all of the CVI tests
    include("test_cvis.jl")
end

@testset "Label Map" begin
    @info "Label Map Testing"

    # Create the ICVI
    cvi = CH()

    # Load the sample data
    data_paths = readdir("data", join=true)
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
        _ = get_cvi!(cvi, sample, label)
    end

    @info "Task map: " cvi.label_map
end

@testset "Constants" begin
    # Test that the constants are exported
    cvi_constants = [
        CVI_MODULES,
        CLUSTERVALIDITYINDICES_VERSION,
    ]
    for local_constants in cvi_constants
        @test @isdefined local_constants
    end
end
