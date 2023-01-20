"""
    types.jl

# Description
Defines all types of the base CVI implementation.
"""

# -----------------------------------------------------------------------------
# STRUCTS
# -----------------------------------------------------------------------------

const CVIParams = Dict{String, Any}

const CVIRecursionCache = Dict{String, Any}

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
    to_el_update::Bool
end

const CVIConfig = OrderedDict{String, CVIParamConfig}

function get_el_type(shape::Integer, type::Type)
    if shape == 1
        el_type = type
    else
        el_type = Array{type, shape - 1}
    end
    return el_type
end

function CVIParamConfig(top_config::CVIConfigDict, name::String)
    subconfig = top_config["params"][name]

    param_config = CVIParamConfig(
        Symbol(name * "_update"),
        Symbol(name * "_add"),
        top_config["container"][subconfig["shape"]]["expand"],
        top_config["container"][subconfig["shape"]]["type"]{subconfig["type"]},
        subconfig["shape"],
        get_el_type(subconfig["shape"], subconfig["type"]),
        subconfig["expand"],
        subconfig["update"] == "element",
    )
    return param_config
end

const CVIStageOrder = Vector{String}

const CVIEvalOrder = Vector{CVIStageOrder}

function recursive_evalorder!(config::CVIConfig, evalorder::CVIEvalOrder, top_config::CVIConfigDict, name::AbstractString)
    # Iterate over all current dependencies
    for dep in top_config["params"][name]["deps"]
        # If we don't have the dependency, crawl through its dependency chain
        if !haskey(config, dep)
            recursive_evalorder!(config, evalorder, top_config, dep)
        end
    end
    # If we have all dependencies, build this parameter name's config
    config[name] = CVIParamConfig(top_config, name)
    # Append the name of the parameter to the evalorder at its correct stage
    stage = top_config["params"][name]["stage"]
    push!(evalorder[stage], name)

    return
end

function build_empty_evalorder(top_config::CVIConfigDict, opts::CVIOpts)
    # Get all of the stages defined in the config
    stages = [top_config["params"][name]["stage"] for name in opts.params]
    # Get the maximum value
    max_stage = maximum(stages)
    # Create an empty CVIEvalOrder
    evalorder = CVIEvalOrder()
    # Push a stage from 1 to max stage to guarantee that there will be a stage index for each parameter
    for _ = 1:max_stage
        push!(evalorder, CVIStageOrder())
    end
    return evalorder
end

function build_config(top_config::CVIConfigDict, opts::CVIOpts)
    # Initialize the strategy
    config = CVIConfig()
    evalorder = build_empty_evalorder(top_config, opts)
    # Iterate over every option that we selected
    for param in opts.params
        # Recursively add its dependencies in deepest order
        recursive_evalorder!(config, evalorder, top_config, param)
    end
    # Clean up the evalorder if we have empty stages
    filter!(v->!isempty(v), evalorder)

    return config, evalorder
end


mutable struct BaseCVI <: CVI
    opts::CVIOpts
    base::CVIBaseParams
    params::CVIParams
    cache::CVIRecursionCache
    config::CVIConfig
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

# function build_evalorder(top_config::CVIConfigDict, opts::CVIOpts)
#     # Get all of the stages defined in the config
#     stages = [top_config["params"][name]["stage"] for name in keys(opts["params"])]
#     evalorder = Vec
# end

function BaseCVI(dim::Integer=0, n_clusters::Integer=0)
    opts = CVIOpts(params=[
        "n",
        "v",
        "CP",
        "G",
        "mu",
        "SEP",
    ])

    config, evalorder = build_config(CVI_TOP_CONFIG, opts)

    cvi = BaseCVI(
        opts,
        CVIBaseParams(dim),
        CVIParams(),
        CVIRecursionCache(),
        config,
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

# const CVI_STRATEGY::CVIStrategy = get_cvi_strategy(CVI_TOP_CONFIG)