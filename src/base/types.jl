"""
    types.jl

# Description
Defines all types of the base CVI implementation.
"""

# -----------------------------------------------------------------------------
# STRUCTS
# -----------------------------------------------------------------------------

mutable struct CVIBaseParams
    label_map::LabelMap
    dim::Int
    n_samples::Int
    mu::Vector{Float}               # dim
    n_clusters::Int
    criterion_value::Float
end

# struct CVICacheParams
#     delta_v::Vector{Float}          # dim
#     diff_x_v::Vector{Float}         # dim
# end

# const ALLOWED_CVI_PARAM_TYPES = Union{
#     CVIExpandVector,
#     CVIExpandMatrix,
#     CVIExpandTensor,
# }

const CVIParams = OrderedDict{String, Any}

const CVIRecursionCache = Dict{String, Any}

const CVIEvalOrder = OrderedDict{String, Any}

@with_kw struct CVIOpts
    params::Vector{String} = [
        "n",
        "v",
        "CP",
        "G",
    ]

    CP_alt::Bool = false
end

mutable struct BaseCVI <: CVI
    opts::CVIOpts
    base::CVIBaseParams
    params::CVIParams
    cache::CVIRecursionCache
    evalorder::CVIEvalOrder
end

# -----------------------------------------------------------------------------
# CONSTRUCTORS
# -----------------------------------------------------------------------------

function CVIBaseParams(dim::Integer=0)
    CVIBaseParams(
        LabelMap(),                 # label_map
        dim,                        # dim
        0,                          # n_samples
        # Vector{Float}(undef, dim),  # mu
        zeros(Float, dim),          # mu
        0,                          # n_clusters
        0.0,                        # criterion_value
    )
end

# function get_evaluation_order(config::CVI_CONFIG)
# end

function BaseCVI(dim::Integer=0, n_clusters::Integer=0)

    opts = CVIOpts()

    cvi = BaseCVI(
        opts,
        CVIBaseParams(dim),
        # CVICacheParams(dim),
        CVIParams(),
        CVIRecursionCache(),
        CVIEvaluation(),
        # CVIElasticParams(dim),
    )

    # Initialize if we know the dimension
    if dim > 0
        init_params!(cvi, dim, n_clusters)
    end

    return cvi
end
