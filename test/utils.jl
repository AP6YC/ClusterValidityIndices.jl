"""
    utils.jl

# Description
Utilities for unit tests of the `ClusterValidityIndices.jl` package.

# Authors
- Sasha Petrenko <sap625@mst.edu>
"""

# -----------------------------------------------------------------------------
# DEPENDENCIES
# -----------------------------------------------------------------------------

using
    Random,
    DelimitedFiles,
    NumericalTypeAliases

# -----------------------------------------------------------------------------
# FUNCTIONS
# -----------------------------------------------------------------------------

"""
Constructs and returns a list of all CVI modules.
"""
function construct_cvis()
    # Construct the cvis as a list
    cvis = [local_cvi() for local_cvi in CVI_MODULES]

    # Return a list of constructed CVIs
    return cvis
end


"""
Get the cvi data specified by the data_file path.

# Arguments
- `data_file::AbstractString`: the CVI test dataset path to load.
"""
function get_cvi_data(data_file::AbstractString)
    # Parse the data
    data = readdlm(data_file, ',')
    data = permutedims(data)
    train_x = data[1:2, :]
    train_y = convert(Array{Int}, data[3, :])

    return train_x, train_y
end

"""
Gets a random bernoulli-sampled subset of the provided data, subsampled at rate p.

# Arguments
- `data::RealMatrix`: the 2-D batch of data to subsample.
- `labels::IntegerVector`: the labels that correspond to the batch of data.
- `p::Real`: the subsampling ratio ∈ (0, 1]
"""
function get_bernoulli_subset(data::RealMatrix, labels::IntegerVector, p::Real)
    # Get the dimensions of the data
    _, n_samples = size(data)

    # Get a random subsamplin of the data
    subset = randsubseq(1:n_samples, p)

    # Return the subset
    return data[:, subset], labels[subset]
end
