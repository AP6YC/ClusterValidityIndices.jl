abstract type CVIType end
abstract type CHType <: CVIType end
abstract type WBType <: CVIType end

# mutable struct BaseCVI{T} <: CVI where T<: CVIType

# function CVIOpts(type::Type{CVIType})
#     if type <: CHType
#         opts = CVIOpts(params = ["n", "v", "CP", "G"])
#     elseif type <: WBType
#         opts = CVIOpts(params = ["n", "v", "CP", "G"])
#     end

#     return opts
# end

# function BaseCVI{T}(dim::Integer=0, n_clusters=0) where T<:CVIType

#     cvi = BaseCVI{T}(

#     )
# end