using
    Parameters,
    DataStructures

include("base/base.jl")

function init_param!(cvi::CVI, name::AbstractString, dim::Integer=0, n_clusters::Integer=0)
    # Build the parameter itself
    cvi.params[name] = build_cvi_param(cvi.evalorder[name].type, dim, n_clusters)
    # Build the parameter's recursion cache
    cvi.cache[name] = build_cvi_cache(cvi.evalorder[name].el_type, cvi.evalorder[name].shape, dim)
end

function init_params!(cvi::CVI, dim::Integer=0, n_clusters::Integer=0)
    for name in cvi.opts.params
        init_param!(cvi, name, dim, n_clusters)
    end
end

function iterate_evalorder!(func::Function, cvi::CVI, args...)
    for name in keys(cvi.evalorder)
        func(cvi, name, args...)
    end
    # foreach(name -> add_strategy!(args...), )
end

function base_add_cluster!(cvi::CVI, sample::RealVector)
    # Increment the number of clusters
    cvi.base.n_clusters += 1

    # Compute the new variables in order
    iterate_evalorder!(add_strategy!, cvi, sample)

    # After computing the recursion cache, extend each parameter with the cache values
    iterate_evalorder!(extend_strategy!, cvi)
end

function base_update_cluster!(cvi::CVI, sample::RealVector, i_label::Integer)
    # Compute the updated parameters in order
    iterate_evalorder!(update_strategy!, cvi, sample, i_label)

    # After computing the recursion cache, reassign each value in its position
    iterate_evalorder!(reassign_strategy!, cvi, i_label)
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
