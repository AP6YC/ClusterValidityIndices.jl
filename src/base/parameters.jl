"""
    parameters.jl

# Description
Implements the functions for each CVI parameter.
"""

# -----------------------------------------------------------------------------
# ADDERS
# -----------------------------------------------------------------------------

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

# -----------------------------------------------------------------------------
# UPDATERS
# -----------------------------------------------------------------------------

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

function mu_update(cvi::CVI, sample::RealVector, i_label::Integer)
    if iszero(cvi.params["mu"])
        cvi.params["mu"] = sample
    else
        cvi.params["mu"] = update_mean(cvi.params["mu"], sample, cvi.base.n_samples)
    end
end

function SEP_update(cvi::CVI, _::RealVector, _::Integer)
    while(length(cvi.params["SEP"]) < cvi.base.n_clusters)
        push!(cvi.params["SEP"], 0.0)
    end
    for ix = 1:cvi.base.n_clusters
        @inbounds cvi.params["SEP"][ix] = cvi.params["n"][ix] * sum((cvi.params["v"][:, ix] - cvi.params["mu"]) .^ 2)
    end
    return
end
