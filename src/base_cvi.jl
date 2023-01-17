using
    Parameters,
    DataStructures

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
end

function CVIBaseParams(dim::Integer=0)
    CVIBaseParams(
        LabelMap(),                 # label_map
        dim,                        # dim
        0,                          # n_samples
        # Vector{Float}(undef, dim),  # mu
        zeros(Float, dim),
        0,                          # n_clusters
        0.0,                        # criterion_value
    )
end

function BaseCVI(dim::Integer=0, n_clusters::Integer=0)
    cvi = BaseCVI(
        CVIOpts(),
        CVIBaseParams(dim),
        # CVICacheParams(dim),
        CVIParams(),
        CVIRecursionCache(),
        # CVIElasticParams(dim),
    )

    # Initialize if we know the dimension
    if dim > 0
        init_params!(cvi, dim, n_clusters)
    end

    return cvi
end

const CVI_CONFIG = Dict(
    "params" => Dict(
        "n" => Dict(
            "shape" => 1,
            "type" => Int,
        ),
        "v" => Dict(
            "shape" => 2,
            "type" => Float,
        ),
        "CP" => Dict(
            "shape" => 1,
            "type" => Float,
        ),
        "G" => Dict(
            "shape" => 2,
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
            "type" => CVIExpandMatrix,
        ),
        3 => Dict(
            "expand" => :expand_strategy_3d!,
            "type" => CVIExpandTensor,
        ),
    ),
)

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
end

const CVIStrategy = Dict{String, CVIParamConfig}

function get_el_type(shape::Integer, type::Type)
    if shape == 1
        el_type = type
    else
        el_type = Array{type, shape - 1}
    end
    return el_type
end

function get_cvi_strategy(config::AbstractDict)
    # Initialize the strategy
    strategy = CVIStrategy()
    for (name, subconfig) in config["params"]
        strategy[name] = CVIParamConfig(
            Symbol(name * "_update"),
            Symbol(name * "_add"),
            config["container"][subconfig["shape"]]["expand"],
            config["container"][subconfig["shape"]]["type"]{subconfig["type"]},
            subconfig["shape"],
            get_el_type(subconfig["shape"], subconfig["type"]),
        )
    end
    return strategy
end

const CVI_STRATEGY::CVIStrategy = get_cvi_strategy(CVI_CONFIG)

function build_0d_strategy(type::Type{<:Real})
    return zero(type)
end

function build_1d_strategy(type::Type{<:AbstractVector}, param_a::Integer)
    return type(undef, param_a)
end

function build_2d_strategy(type::Type{<:AbstractMatrix}, param_a::Integer, param_b::Integer)
    return type(undef, param_a, param_b)
end

function build_3d_strategy(type::Type{<:AbstractArray{T, 3}}, param_a::Integer, param_b::Integer) where {T}
    return type(undef, param_a, param_a, param_b)
end

function build_cvi_param(type::Type{<:CVIExpandVector}, ::Integer, n_clusters::Integer)
    # return type(undef, n_clusters)
    return build_1d_strategy(type, n_clusters)
end

function build_cvi_param(type::Type{<:CVIExpandMatrix}, dim::Integer, n_clusters::Integer)
    # return type(undef, dim, n_clusters)
    return build_2d_strategy(type, dim, n_clusters)
end

function build_cvi_param(type::Type{<:CVIExpandTensor}, dim::Integer, n_clusters::Integer)
    # return type(undef, dim, dim, n_clusters)
    return build_3d_strategy(type, dim, n_clusters)
end

function build_cvi_cache(type::Type, shape::Integer, dim::Integer)
    if shape == 1
        constructed = build_0d_strategy(type)
    elseif shape == 2
        constructed = build_1d_strategy(type, dim)
    elseif shape == 3
        constructed = build_2d_strategy(type, dim, dim)
    else
        error("Unsupported cache variable shape provided.")
    end
    return constructed
end

function init_param!(cvi::CVI, name::AbstractString, dim::Integer=0, n_clusters::Integer=0)
    # Build the parameter itself
    cvi.params[name] = build_cvi_param(CVI_STRATEGY[name].type, dim, n_clusters)
    # Build the parameter's recursion cache
    cvi.cache[name] = build_cvi_cache(CVI_STRATEGY[name].el_type, CVI_STRATEGY[name].shape, dim)
end

function init_params!(cvi::CVI, dim::Integer=0, n_clusters::Integer=0)
    for name in cvi.opts.params
        init_param!(cvi, name, dim, n_clusters)
    end
end

function extend_strategy!(cvi::CVI, name::AbstractString)
    eval(CVI_STRATEGY[name].expand)(cvi.params[name], cvi.cache[name])
end

function add_strategy!(cvi::CVI, sample::RealVector, name::AbstractString)
    cvi.cache[name] = eval(CVI_STRATEGY[name].add)(cvi, sample)
    return
end

function base_add_cluster!(cvi::CVI, sample::RealVector)
    # Increment the number of clusters
    cvi.base.n_clusters += 1

    # Compute the new variables in order
    for name in keys(cvi.params)
        add_strategy!(cvi, sample, name)
    end

    # After computing the recursion cache, assign each
    for name in keys(cvi.params)
        extend_strategy!(cvi, name)
    end
end

function n_add(_::CVI, _::RealVector)
    return 1
end

function v_add(_::CVI, sample::RealVector)
    return sample
end

function CP_add(cvi::CVI, sample::RealVector)
    return cvi.opts.CP_alt ? dot(sample, sample) : 0.0
end

function G_add(cvi::CVI, sample::RealVector)
    return cvi.opts.CP_alt ? sample : zeros(cvi.base.dim)
end

# function SEP_add(cvi::CVI, sample::realVector)
#     for ix = 1:cvi.base.n_clusters
#         cvi.params[SEP[ix] = cvi.params.n[ix] * sum((cvi.params.v[:, ix] - cvi.mu) .^ 2)
#     end
# end


function n_update(cvi::CVI, ::RealVector, i_label::Integer)
    return cvi.params["n"][i_label] + 1
end

function v_update(cvi::CVI, sample::RealVector, i_label::Integer)
    # Use the cache version of n_new that was just computed
    return update_mean(cvi.params["v"][:, i_label], sample, cvi.cache["n"])
    # return update_mean(cvi.params["v"][:, i_label], sample, n_new)
end

function delta_v_update(cvi::CVI, ::RealVector, i_label::Integer)
    # Use the cache version of v_new that was just computed
    return cvi.params["v"][:, i_label] - cvi.cache["v"]
    # return cvi.params["v"][:, i_label] - v_new
end

function CP_update(cvi::CVI, sample::RealVector, i_label::Integer)
    # TEMP: intermediate variables recomputed here.
    # Find a way to cache them separately from recursion cache.
    delta_v = cvi.params["v"][:, i_label] - cvi.cache["v"]
    diff_x_v = sample - cvi.cache["v"]
    # Compute the new compactness of the cluster i_label
    CP_new = (
        cvi.params["CP"][i_label]
        + dot(diff_x_v, diff_x_v)
        + cvi.params["n"][i_label] * dot(delta_v, delta_v)
        + 2 * dot(delta_v, cvi.params["G"][:, i_label])
    )
    # CP_new = (
    #     cvi.params["CP"][i_label]
    #     + dot(cvi.cache["diff_x_v"], cvi.cache["diff_x_v"])
    #     + cvi.params["n"][i_label] * dot(cvi.cache["delta_v"], cvi.cache["delta_v"])
    #     + 2 * dot(cvi.cache["delta_v"], cvi.params["G"][:, i_label])
    # )
    return CP_new
end

function G_update(cvi::CVI, sample::RealVector, i_label::Integer)
    # TEMP: intermediate variables recomputed here.
    # Find a way to cache them separately from recursion cache.
    delta_v = cvi.params["v"][:, i_label] - cvi.cache["v"]
    diff_x_v = sample - cvi.cache["v"]
    # Compute the new G of cluster i_label
    G_new = (
        cvi.params["G"][:, i_label]
        + diff_x_v
        + cvi.params["n"][i_label] * delta_v
    )
    # G_new = (
    #     cvi.params["G"][:, i_label]
    #     + cvi.cache["diff_x_v"]
    #     + cvi.params["n"][i_label] * cvi.cache["delta_v"]
    # )
    return G_new
end

# function add_strategy!(cvi::CVI, sample::RealVector, name::AbstractString)
#     cvi.cache[name] = eval(CVI_STRATEGY[name].add)(cvi, sample)
#     return
# end

function update_strategy!(cvi::CVI, sample::RealVector, i_label::Integer, name::AbstractString)
    cvi.cache[name] = eval(CVI_STRATEGY[name].update)(cvi, sample, i_label)
    return
end

function reassign_param!(param::CVIExpandVector, value::Real, i_label::Integer)
    @inbounds param[i_label] = value
end

function reassign_param!(param::CVIExpandMatrix, value::RealVector, i_label::Integer)
    @inbounds param[:, i_label] = value
end

function reassign_param!(param::CVIExpandTensor, value::RealMatrix, i_label::Integer)
    @inbounds param[:, :, i_label] = value
end

function reassign_strategy!(cvi::CVI, i_label::Integer, name::AbstractString)
    reassign_param!(cvi.params[name], cvi.cache[name], i_label)
end

function base_update_cluster!(cvi::CVI, sample::RealVector, i_label::Integer)
    # Compute the new variables in order
    for name in keys(cvi.params)
        # add_strategy!(cvi, sample, name)
        update_strategy!(cvi, sample, i_label, name)
    end

    for name in keys(cvi.params)
        reassign_strategy!(cvi, i_label, name)
    end
    # # After computing the recursion cache, assign each
    # for name in keys(cvi.params)
    #     extend_strategy!(cvi, name, cvi.cache[name])
    # end
end

function init_cvi_update!(cvi::BaseCVI, sample::RealVector, label::Integer)
    # Get the internal label
    i_label = get_internal_label!(cvi.base.label_map, label)

    # Increment to a new sample count
    cvi.base.n_samples += 1

    # If uninitialized, setup the CVI
    # if isempty(cvi.base.mu)
    if iszero(cvi.base.mu)
        cvi.base.mu = sample
        # setup!(cvi, sample)
    # Otherwise, update the mean
    else
        cvi.base.mu = update_mean(cvi.base.mu, sample, cvi.base.n_samples)
    end

    # Return the internal label
    return i_label
end

function param_inc!(cvi::BaseCVI, sample::RealVector, label::Integer)
    # Initialize the batch update
    i_label = init_cvi_update!(cvi, sample, label)

    if i_label > cvi.base.n_clusters
        base_add_cluster!(cvi, sample)
    else
        base_update_cluster!(cvi, sample, i_label)
    end
end

# Criterion value evaluation function
function evaluate!(cvi::BaseCVI)
    SEP = zeros(cvi.base.n_clusters)
    for ix = 1:cvi.base.n_clusters
        SEP[ix] = cvi.params["n"][ix] * sum((cvi.params["v"][:, ix] - cvi.base.mu) .^ 2)
    end
    # Within group sum of squares
    WGSS = sum(cvi.params["CP"])
    if cvi.base.n_clusters > 1
        # Between groups sum of squares
        BGSS = sum(SEP)
        # CH index value
        cvi.base.criterion_value = (
            (BGSS / WGSS)
            * ((cvi.base.n_samples - cvi.base.n_clusters) / (cvi.base.n_clusters - 1))
        )
    else
        cvi.base.criterion_value = 0.0
    end
end

function get_cvi!(cvi::BaseCVI, sample::RealVector, label::Integer)
    # Update the ICVI parameters
    param_inc!(cvi, sample, label)

    # Compute the criterion value
    evaluate!(cvi)

    # Return that value
    return cvi.base.criterion_value
end


# function update_cluster!(cvi::CVI, sample::RealVector, i_label::Integer)
#     # Update the number of samples in the cluster
#     cvi.params.n[i_label] + 1
#     # Compute the new prototype vector
#     v_new = update_mean(cvi.params.v[:, i_label], sample, n_new)
#     # Compute delta_v and diff_x_v
#     compute_cache!(cvi, sample, i_label)
#     # Compute the CP_new
#     CP_new = CP_update(cvi, sample, i_label)
#     # Compute the G_new
#     G_new = G_update(cvi, sample, i_label)
#     # Update parameters
#     update_params!(cvi.params, i_label, n_new, CP_new, v_new, G_new)
# end


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
