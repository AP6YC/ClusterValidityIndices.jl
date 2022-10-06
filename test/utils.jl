"""
    utils.jl

# Description
Utilities for unit tests of the `ClusterValidityIndices.jl` package.

# Authors
- Sasha Petrenko <sap625@mst.edu>
"""

using Random
using DelimitedFiles

"""
    get_cvi_data(data_file::String)

Get the cvi data specified by the data_file path.
"""
function get_cvi_data(data_file::String)
    # Parse the data
    data = readdlm(data_file, ',')
    data = permutedims(data)
    train_x = data[1:2, :]
    train_y = convert(Array{Int}, data[3, :])

    return train_x, train_y
end # get_cvi_data(data_file::String)

"""
    get_bernoulli_subset(data::ClusterValidityIndices.RealMatrix, labels::ClusterValidityIndices.IntegerVector, p::Real)
"""
function get_bernoulli_subset(data::ClusterValidityIndices.RealMatrix, labels::ClusterValidityIndices.IntegerVector, p::Real)
    # Get the dimensions of the data
    dim, n_samples = size(data)

    # Get a random subsamplin of the data
    subset = randsubseq(1:n_samples, p)

    # Return the subset
    return data[:, subset], labels[subset]
end # get_bernoulli_subset(data::ClusterValidityIndices.RealMatrix, labels::ClusterValidityIndices.IntegerVector, p::Real)
