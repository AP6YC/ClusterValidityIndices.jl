"""
Main module for `ClusterValidityIndices.jl`, a Julia package of metrics for unsupervised learning.

This module exports all of the CVI modules, options, and utilities used by the `ClusterValidityIndices.jl package.`

# Exports

$(EXPORTS)

"""
module ClusterValidityIndices

# --------------------------------------------------------------------------- #
# USINGS
# --------------------------------------------------------------------------- #

# Package dependencies
using DocStringExtensions   # Docstring utilities
using Statistics: mean
using LinearAlgebra

# --------------------------------------------------------------------------- #
# INCLUDES
# --------------------------------------------------------------------------- #

# Common structures
include("common.jl")

# CVI utility functions
include("utils.jl")

# All of the CVI modules
include("CVI/CVI.jl")

# --------------------------------------------------------------------------- #
# EXPORTS
# --------------------------------------------------------------------------- #

# Export all public names
export

    # Abstract types
    CVI,

    # CVI constructors
    XB,
    DB,
    PS,
    CH,
    cSIL,
    GD53,
    GD43,
    WB,
    rCIP,
    # CONN,

    # CVI functions
    param_inc!,
    param_batch!,
    evaluate!,
    get_icvi!,
    get_cvi!,

    # CVI utilities
    sort_cvi_data,
    relabel_cvi_data

    # Not exported
    # get_cvi_data
    # get_bernoulli_subset
    # showtypetree

end
