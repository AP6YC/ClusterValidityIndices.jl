"""
    types.jl

# Description
Defines all types of the base CVI implementation.
"""

# -----------------------------------------------------------------------------
# STRUCTS
# -----------------------------------------------------------------------------

@with_kw struct CVIOpts
    params::Vector{String} = [
        "n",
        "v",
        "CP",
        "G",
    ]

    CP_alt::Bool = false
end

mutable struct CVIBaseParams
    label_map::LabelMap
    dim::Int
    n_samples::Int
    mu::Vector{Float}               # dim
    n_clusters::Int
    criterion_value::Float
end

const CVIParams = Dict{String, Any}

const CVIRecursionCache = Dict{String, Any}


"""
An object containing all of the information about a single type of CVI parameter.

This includes symbolic pointers to its related functions, the type of the parameter, its shape, and the subsequent element type for expansion.
"""
struct CVIParamConfig
    update::Symbol
    add::Symbol
    expand::Symbol
    type::Type
    shape::Int
    el_type::Type
    to_expand::Bool
end

function get_el_type(shape::Integer, type::Type)
    if shape == 1
        el_type = type
    else
        el_type = Array{type, shape - 1}
    end
    return el_type
end

const CVIEvalOrder = OrderedDict{String, CVIParamConfig}

function CVIParamConfig(config::CVIConfigDict, name::String)
    subconfig = config["params"][name]

    param_config = CVIParamConfig(
        Symbol(name * "_update"),
        Symbol(name * "_add"),
        config["container"][subconfig["shape"]]["expand"],
        config["container"][subconfig["shape"]]["type"]{subconfig["type"]},
        subconfig["shape"],
        get_el_type(subconfig["shape"], subconfig["type"]),
        subconfig["growth"] == "extend",
        # subconfig["to_expand"]
    )
    return param_config
end

function recursive_evalorder!(evalorder::CVIEvalOrder, config::CVIConfigDict, name::AbstractString)
    # Iterate over all current dependencies
    for dep in config["params"][name]["deps"]
        # If we don't have the dependency, crawl through its dependency chain
        if !haskey(evalorder, name)
            recursive_evalorder!(evalorder, config, dep)
        end
    end
    # If we have all dependencies, build this parameter name's config
    evalorder[name] = CVIParamConfig(config, name)
end

function get_cvi_evalorder(config::CVIConfigDict, opts::CVIOpts)::CVIEvalOrder
    # Initialize the strategy
    evalorder = CVIEvalOrder()
    # Iterate over every option that we selected
    for param in opts.params
        # Recursively add its dependencies in deepest order
        recursive_evalorder!(evalorder, config, param)
    end
    return evalorder
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

function BaseCVI(dim::Integer=0, n_clusters::Integer=0)
    opts = CVIOpts()

    evalorder = get_cvi_evalorder(CVI_CONFIG, opts)

    cvi = BaseCVI(
        opts,
        CVIBaseParams(dim),
        CVIParams(),
        CVIRecursionCache(),
        evalorder,
    )

    # Initialize if we know the dimension
    if dim > 0
        init_params!(cvi, dim, n_clusters)
    end

    return cvi
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

# const CVIStrategy = Dict{String, CVIParamConfig}

# function get_cvi_strategy(config::AbstractDict)
#     # Initialize the strategy
#     strategy = CVIStrategy()
#     for (name, subconfig) in config["params"]
#         strategy[name] = CVIParamConfig(
#             Symbol(name * "_update"),
#             Symbol(name * "_add"),
#             config["container"][subconfig["shape"]]["expand"],
#             config["container"][subconfig["shape"]]["type"]{subconfig["type"]},
#             subconfig["shape"],
#             get_el_type(subconfig["shape"], subconfig["type"]),

#         )
#     end
#     return strategy
# end

# const CVI_STRATEGY::CVIStrategy = get_cvi_strategy(CVI_CONFIG)