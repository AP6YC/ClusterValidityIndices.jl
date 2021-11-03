module ClusterValidityIndices

# Package dependencies
using Statistics: mean

# Common structures
include("common.jl")

# CVI utility functions
include("utils.jl")

# All of the CVI modules
include("CVI/CVI.jl")

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
