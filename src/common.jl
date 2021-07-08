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

"""
get_icvi!(cvi::T, x::Array{N, 1}, y::M) where {T<:AbstractCVI, N<:Real, M<:Int}

Porcelain: update and compute the criterion value incrementally and return it.
"""
function get_icvi!(cvi::T, x::Array{N, 1}, y::M) where {T<:AbstractCVI, N<:Real, M<:Int}
# Update the ICVI parameters
param_inc!(cvi, x, y)

# Compute the criterion value
evaluate!(cvi)

# Return that value
return cvi.criterion_value
end # get_icvi!(cvi::T, x::Array{N, 1}, y::M) where {T<:AbstractCVI, N<:Real, M<:Int}

"""
get_cvi!(cvi::T, x::Array{N, 2}, y::Array{M, 1}) where {T<:AbstractCVI, N<:Real, M<:Int}

Porcelain: update compute the criterion value in batch and return it.
"""
function get_cvi!(cvi::T, x::Array{N, 2}, y::Array{M, 1}) where {T<:AbstractCVI, N<:Real, M<:Int}
# Update the CVI parameters in batch
param_batch!(cvi, x, y)

# Compute the criterion value
evaluate!(cvi)

# Return that value
return cvi.criterion_value
end # get_cvi!(cvi::T, x::Array{N, 2}, y::Array{M, 1}) where {T<:AbstractCVI, N<:Real, M<:Int}
