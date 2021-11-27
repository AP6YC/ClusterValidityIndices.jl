"""
    common.jl

Description:
    All common types, aliases, structs, and methods for the ClusterValidityIndices.jl package.
"""
# -------------------------------------------
# Abstract types
# -------------------------------------------

# Type for all CVIs
abstract type CVI end

# -------------------------------------------
# Aliases
# -------------------------------------------
#   **Taken from StatsBase.jl**
#
#  These types signficantly reduces the need of using
#  type parameters in functions (which are often just
#  for the purpose of restricting the arrays to real)
#
# These could be removed when the Base supports
# covariant type notation, i.e. AbstractVector{<:Real}

# Real-numbered aliases
const RealArray{T<:Real, N} = AbstractArray{T, N}
const RealVector{T<:Real} = AbstractArray{T, 1}
const RealMatrix{T<:Real} = AbstractArray{T, 2}

# Integered aliases
const IntegerArray{T<:Integer, N} = AbstractArray{T, N}
const IntegerVector{T<:Integer} = AbstractArray{T, 1}
const IntegerMatrix{T<:Integer} = AbstractArray{T, 2}

# Specifically floating-point aliases
const RealFP = Union{Float32, Float64}

# System's largest native floating point variable
const Float = (Sys.WORD_SIZE == 64 ? Float64 : Float32)

# Internal label mapping for incremental CVIs
const LabelMap = Dict{Int, Int}

# -------------------------------------------
# Methods
# -------------------------------------------

"""
    get_icvi!(cvi::CVI, x::RealVector, y::Integer)

Porcelain: update and compute the criterion value incrementally and return it.
"""
function get_icvi!(cvi::CVI, x::RealVector, y::Integer)
    # Update the ICVI parameters
    param_inc!(cvi, x, y)

    # Compute the criterion value
    evaluate!(cvi)

    # Return that value
    return cvi.criterion_value
end # get_icvi!(cvi::CVI, x::RealVector, y::Integer)

"""
    get_cvi!(cvi::CVI, x::RealMatrix, y::IntegerVector)

Porcelain: update compute the criterion value in batch and return it.
"""
function get_cvi!(cvi::CVI, x::RealMatrix, y::IntegerVector)
    # Update the CVI parameters in batch
    param_batch!(cvi, x, y)

    # Compute the criterion value
    evaluate!(cvi)

    # Return that value
    return cvi.criterion_value
end # get_cvi!(cvi::CVI, x::RealMatrix, y::IntegerVector)

"""
    get_internal_label!(label_map::LabelMap, label::Int)

Get the internal label and update the label map if the label is new.
"""
function get_internal_label!(label_map::LabelMap, label::Int)
    # If the label map contains the key, return that internal label
    if haskey(label_map, label)
        internal_label = label
    # Otherwise, increment the internal label to preserve monotonicity and store
    else
        internal_label = length(label_map) + 1
        label_map[label] = internal_label
    end

    return internal_label
end # get_internal_label!(label_map::LabelMap, label::Int)
