module ClusterValidityIndices

using Statistics: mean

abstract type AbstractCVI end

include("CVI/CVI.jl")

# Export all public names
export

    # Abstract types
    AbstractCVI,

    # CVI
    XB,
    DB,
    PS,
    # CONN,
    param_inc!,
    param_batch!,
    evaluate!,
    get_icvi!,
    get_cvi!

end
