using
    Parameters,
    DataStructures

mutable struct CVIBaseParams
    label_map::LabelMap
    dim::Int
    n_samples::Int
    mu::Vector{Float}               # dim
    # n::CVIExpandVector{Float}       # n_clusters
    # v::CVIExpandMatrix{Float}       # dim x n_clusters
    n_clusters::Int
    criterion_value::Float
end

# struct CVICacheParams
#     delta_v::Vector{Float}          # dim
#     diff_x_v::Vector{Float}         # dim
# end

const ALLOWED_CVI_PARAM_TYPES = Union{
    CVIExpandVector,
    CVIExpandMatrix,
    CVIExpandTensor,
}

const CVIParams = OrderedDict{String, ALLOWED_CVI_PARAM_TYPES}

const CVIRecursionCache = Dict{String, Any}

@with_kw struct CVIOpts
    params::Vector{String}
    CP_alt::Bool = false
end

mutable struct BaseCVI
    opts::CVIOpts
    base::CVIBaseParams
    # cache::CVICacheParams
    params::CVIParams
    cache::CVIRecursionCache
end

# function CVICacheParams(dim::Integer=0)
#     CVICacheParams(
#         Vector{Float}(undef, dim),    # delta_v
#         Vector{Float}(undef, dim),    # diff_x_v
#     )
# end

function CVIBaseParams(dim::Integer=0)
    CVIBaseParams(
        LabelMap(),                 # label_map
        dim,                        # dim
        0,                          # n_samples
        Vector{Float}(undef, dim),  # mu
        0,                          # n_clusters
        0.0,                        # criterion_value
    )
end

function BaseCVI(dim)
    BaseCVI(
        CVIOpts(),
        CVIBaseParams(dim),
        # CVICacheParams(dim),
        CVIParams(),
        CVIRecursionCache(),
        # CVIElasticParams(dim),
    )
end

const CVI_CONFIG = Dict(
    "params" => Dict(
        "n" => Dict(
            "dim" => 1,
            "type" => Int,
        ),
        "v" => Dict(
            "dim" => 2,
            "type" => Float,
        ),
        "CP" => Dict(
            "dim" => 1,
            "type" => Float,
        ),
        "G" => Dict(
            "dim" => 2,
            "type" => Float,
        ),
    ),
    "container" => Dict(
        1 => Dict(
            "expand" => :expand_strategy_1d!,
            "type" => CVIExpandVector,
        ),
        2 => Dict(
            "expand" => :expand_strategy_2d!,
            "type" => CVIExpandMatrix
        ),
        3 => Dict(
            "expand" => :expand_strategy_3d!,
            "type" => CVIExpandTensor,
        ),
    ),
    # "funcs" => [
    #     "add",
    #     "update",
    # ],
)

struct CVIParamConfig
    update::Symbol
    add::Symbol
    expand::Symbol
    type::Type
end

const CVIStrategy = Dict{String, CVIParamConfig}

function get_cvi_strategy(config::AbstractDict)
    # Initialize the strategy
    strategy = CVIStrategy()
    for (name, subconfig) in config["params"]
        strategy[name] = CVIParamConfig(
            Symbol(name * "_update"),
            Symbol(name * "_add"),
            config["container"][subconfig["dim"]]["expand"],
            config["container"][subconfig["dim"]]["type"]{subconfig["type"]},
        )
    end
    return strategy
end

const CVI_STRATEGY::CVIStrategy = get_cvi_strategy(CVI_CONFIG)

function build_cvi_param(type::Type, dim::Integer=0, n_clusters::Integer=0)
    if type <: CVIExpandVector
        constructed = type(undef, n_clusters)
    elseif type <: CVIExpandMatrix
        constructed = type(undef, dim, n_clusters)
    elseif type <: CVIExpandTensor
        constructed = type(undef, dim, dim, n_clusters)
    else
        error("Unsupported CVI parameter type being requested for construction.")
    end
    return constructed
end

function init_param!(cvi::CVI, name::AbstractString, dim::Integer=0, n_clusters::Integer=0)
    cvi.params[name] = build_cvi_param(CVI_STRATEGY[name].type, dim, n_clusters)
end

function init_params!(cvi::CVI, dim::Integer=0, n_clusters::Integer=0)
    for name in cvi.opts.params
        init_param!(cvi, name, dim, n_clusters)
    end
end

# function BaseCVI(dim::Integer=0, n_cluster::Integer=0)

# end

function base_add_cluster!(cvi::CVI, sample::RealVector)
    for (name, param) in cvi.params
        eval(CVI_STRATEGY[name].add)(cvi, sample)
    end
end

function n_add!(_::CVI, _::RealVector)
    return 1
end

function v_add!(_::CVI, sample::RealVector)
    return sample
end

function CP_add!(cvi::CVI, sample::RealVector)
    return cvi.opts.CP_alt ? dot(sample, sample) : 0.0
end

function G_add!(cvi::CVI, sample::RealVector)
    return cvi.opts.CP_alt ? sample : zeros(cvi.dim)
end

function CP_update(cvi::CVI, i_label::Integer)
    CP_new = (
        cvi.params["CP"][i_label]
        + dot(cvi.cache["diff_x_v"], cvi.cache["diff_x_v"])
        + cvi.params["n"][i_label] * dot(cvi.cache["delta_v"], cvi.cache["delta_v"])
        + 2 * dot(cvi.cache["delta_v"], cvi.params["G"][:, i_label])
    )
    return CP_new
end

function G_update(cvi::CVI, i_label::Integer)
    G_new = (
        cvi.params["G"][:, i_label]
        + cvi.cache["diff_x_v"]
        + cvi.params["n"][i_label] * cvi.cache["delta_v"]
    )
    return G_new
end

function update_cluster!(cvi::CVI, sample::RealVector, i_label::Integer)
    # Update the number of samples in the cluster
    cvi.params.n[i_label] + 1
    # Compute the new prototype vector
    v_new = update_mean(cvi.params.v[:, i_label], sample, n_new)
    # Compute delta_v and diff_x_v
    compute_cache!(cvi, sample, i_label)
    # Compute the CP_new
    CP_new = CP_update(cvi, i_label)
    # Compute the G_new
    G_new = G_update(cvi, i_label)
    # Update parameters
    update_params!(cvi.params, i_label, n_new, CP_new, v_new, G_new)
end


# function unsafe_replace_vector!(v_old::RealVector, v_new::RealVector)
#     for ix in eachindex(v_old)
#         @inbounds v_old[ix] = v_new[ix]
#     end
# end

# function replace_vector!(v_old::RealVector, v_new::RealVector)
#     unsafe_replace_vector!(v_old, v_new)
# end

# function compute_cache!(cvi::CVI, sample::RealVector, i_label::Integer)
#     replace_vector!(cvi.delta_v, cvi.params.v[:, i_label] - v_new)
#     replace_vector!(cvi.diff_x_v, sample - v_new)
# end


# function n_init(dim::Integer=0, n_clusters::Integer=0)
#     return CVIExpandVector{Int}(undef, n_clusters)
# end

# function v_init(dim::Integer=0, n_clusters::Integer=0)
#     return CVIExpandMatrix{Float}(undef, dim, n_clusters)
# end

# function CP_init(dim::Integer=0, n_clusters::Integer=0)
#     return CVIExpandVector{Int}(undef, n_clusters)
# end

# function G_init()
#     return CVIExpandMatrix{Float}(undef, dim, n_clusters)
# end

# function get_cvi_strategy(config::AbstractDict)
    # # Add the function strategies
    # strategy = Dict(
    #     name => Dict(
    #         func => Symbol(name * "_" * func) for func in config["funcs"]
    #     )
    #     for name in keys(config["params"])
    # )
    # # Add the type and expansion strategies
    # for (name, subconfig) in config["params"]
    #     strategy[name]["expand"] = config["container"][subconfig["dim"]]["expand"]
    #     strategy[name]["type"] = config["container"][subconfig["dim"]]["type"]
    # end
# end
