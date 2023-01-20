"""
    strategies.jl

# Description
A collection of low-level functions for handling how parameters are constructed and updated.
"""

# -----------------------------------------------------------------------------
# BUILD
#
# These functions handle the construction of new parameters based upon their
# types, shapes, and the feature dimensions.
# -----------------------------------------------------------------------------

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
    return build_1d_strategy(type, n_clusters)
end

function build_cvi_param(type::Type{<:CVIExpandMatrix}, dim::Integer, n_clusters::Integer)
    # type(undef, dim, n_clusters)
    return build_2d_strategy(type, dim, n_clusters)
end

function build_cvi_param(type::Type{<:CVIExpandTensor}, dim::Integer, n_clusters::Integer)
    # type(undef, dim, dim, n_clusters)
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
    # return constructed
    return zero(constructed)
end

function handle_strategy!(func::Symbol, args...)
    eval(func)(args...)
end

# -----------------------------------------------------------------------------
# ADD
#
# These functions identify how a parameter is computed for a new cluster and
# added to the cache.
# -----------------------------------------------------------------------------

function add_strategy!(cvi::CVI, name::AbstractString, sample::RealVector)
    if cvi.config[name].to_el_update
        cvi.cache[name] = handle_strategy!(cvi.config[name].add, cvi, sample)
    end
    return
end

# -----------------------------------------------------------------------------
# EXTEND
#
# These functions identify how a parameter is grown/extended at its end.
# -----------------------------------------------------------------------------

function extend_strategy!(cvi::CVI, name::AbstractString)
    # eval(cvi.config[name].expand)(cvi.params[name], cvi.cache[name])
    if cvi.config[name].to_expand
        handle_strategy!(cvi.config[name].expand, cvi.params[name], cvi.cache[name])
    end
    return
end

# -----------------------------------------------------------------------------
# UPDATE
#
# These functions identify how a parameter is updated from existing values and
# added to the cache.
# -----------------------------------------------------------------------------

function update_strategy!(cvi::CVI, name::AbstractString, sample::RealVector, i_label::Integer)
    # If the parameter is extended via the recursion cache
    if cvi.config[name].to_el_update
        cvi.cache[name] = handle_strategy!(cvi.config[name].update, cvi, sample, i_label)
    # Otherwise, it is updated in place
    else
        handle_strategy!(cvi.config[name].update, cvi, sample, i_label)
    end
    return
end

# -----------------------------------------------------------------------------
# REASSIGN
#
# These functions handle the syntax for how a parameter is reassigned its
# values at cluster index i_label.
# -----------------------------------------------------------------------------

function reassign_param!(param::CVIExpandVector, value::Real, i_label::Integer)
    @inbounds param[i_label] = value
end

function reassign_param!(param::CVIExpandMatrix, value::RealVector, i_label::Integer)
    @inbounds param[:, i_label] = value
end

function reassign_param!(param::CVIExpandTensor, value::RealMatrix, i_label::Integer)
    @inbounds param[:, :, i_label] = value
end

function reassign_strategy!(cvi::CVI, name::AbstractString, i_label::Integer)
    # If we are element updating, run the reassignment
    if cvi.config[name].to_el_update
        reassign_param!(cvi.params[name], cvi.cache[name], i_label)
    end
end

