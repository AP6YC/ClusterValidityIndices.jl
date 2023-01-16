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

struct CVICacheParams
    delta_v::Vector{Float}          # dim
    diff_x_v::Vector{Float}         # dim
end

const ALLOWED_CVIPARAMS = Union{
    CVIExpandVector,
    CVIExpandMatrix,
    CVIExpandTensor,
}

const CVIParams = Dict{String, ALLOWED_CVIPARAMS}

mutable struct BaseCVI
    base::CVIBaseParams
    cache::CVICacheParams
    params::CVIParams
end


function CVICacheParams(dim::Integer=0)
    CVICacheParams(
        Vector{Float}(undef, dim),    # delta_v
        Vector{Float}(undef, dim),    # diff_x_v
    )
end

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
        CVIBaseParams(dim),
        CVICacheParams(dim),
        CVIParams(),
        # CVIElasticParams(dim),
    )
end

const CVI_PARAMS = [
    "n",
    "v",
    "CP",
    "G",
]

const CVI_PARAM_FUNCS = [
    "init",
    "add",
    "update",
]

const CVI_STRATEGY = Dict(
    param => Dict(
        func => Symbol(param * "_" * func)
        for func in CVI_PARAM_FUNCS
    )
    for param in CVI_PARAMS
)

# const CVI_STRATEGY = Dict(
#     "n" => Dict(
#         "init" => :n_init,
#         "add" => :n_add,
#         "update" => :n_update
#     ),
#     "v" => Dict(
#         "init" => :v_init,
#         "add" =>
#     ),
#     "CP" => :CP_init,
#     "G" => :G_init,
# )


function unsafe_replace_vector!(v_old::RealVector, v_new::RealVector)
    for ix in eachindex(v_old)
        @inbounds v_old[ix] = v_new[ix]
    end
end

function replace_vector!(v_old::RealVector, v_new::RealVector)
    unsafe_replace_vector!(v_old, v_new)
end

function compute_cache!(cvi::CVI, sample::RealVector, i_label::Integer)
    replace_vector!(cvi.delta_v, cvi.params.v[:, i_label] - v_new)
    replace_vector!(cvi.diff_x_v, sample - v_new)
end

function CP_update(cvi::CVI, i_label::Integer)
    CP_new = (
        cvi.params.CP[i_label]
        + dot(cvi.cache.diff_x_v, cvi.cache.diff_x_v)
        + cvi.params.n[i_label] * dot(cvi.cache.delta_v, cvi.cache.delta_v)
        + 2 * dot(cvi.cache.delta_v, cvi.params.G[:, i_label])
    )
    return CP_new
end

function G_update(cvi::CVI, i_label::Integer)
    G_new = (
        cvi.params.G[:, i_label]
        + cvi.cache.diff_x_v
        + cvi.params.n[i_label] * cvi.cache.delta_v
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
