module ClusterValidityIndices

using Statistics: mean

abstract type AbstractCVI end

# All of the CVI modules
include("CVI/CVI.jl")

# CVI utility functions
include("utils.jl")

# Export all public names
export

    # Abstract types
    AbstractCVI,

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
