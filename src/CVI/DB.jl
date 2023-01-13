"""
    DB.jl

# Description
This is a Julia port of a MATLAB implementation of batch and incremental
Davies-Bouldin (DB) Cluster Validity Index.

# Authors
- MATLAB implementation: Leonardo Enzo Brito da Silva
- Julia port: Sasha Petrenko <sap625@mst.edu>

# References
[1] D. L. Davies and D. W. Bouldin, "A cluster separation measure,"
IEEE Transaction on Pattern Analysis and Machine Intelligence, vol. 1,
no. 2, pp. 224-227, Feb. 1979.
[2] M. Moshtaghi, J. C. Bezdek, S. M. Erfani, C. Leckie, and J. Bailey,
"Online Cluster Validity Indices for Streaming Data," ArXiv e-prints, 2018,
arXiv:1801.02937v1 [stat.ML]. [Online].
[3] M. Moshtaghi, J. C. Bezdek, S. M. Erfani, C. Leckie, J. Bailey, "Online
cluster validity indices for performance monitoring of streaming data clustering,"
Int. J. Intell. Syst., pp. 1-23, 2018.
"""

# References string
local_references = """
# References
1. D. L. Davies and D. W. Bouldin, "A cluster separation measure," IEEE Transaction on Pattern Analysis and Machine Intelligence, vol. 1, no. 2, pp. 224-227, Feb. 1979.
2. M. Moshtaghi, J. C. Bezdek, S. M. Erfani, C. Leckie, and J. Bailey, "Online Cluster Validity Indices for Streaming Data," ArXiv e-prints, 2018, arXiv:1801.02937v1 [stat.ML]. [Online].
3. M. Moshtaghi, J. C. Bezdek, S. M. Erfani, C. Leckie, J. Bailey, "Online cluster validity indices for performance monitoring of streaming data clustering," Int. J. Intell. Syst., pp. 1-23, 2018.
"""

"""
The stateful information of the Davies-Bouldin (DB) Cluster Validity Index.

$(local_references)
"""
mutable struct DB <: CVI
    label_map::LabelMap
    dim::Int
    n_samples::Int
    mu::Vector{Float}                       # dim
    D::Matrix{Float}                        # n_clusters x n_clusters
    S::CVIExpandVector{Float}               # dim
    params::CVIElasticParams
    n_clusters::Int
    criterion_value::Float
end

"""
Constructor for the Davies-Bouldin (DB) Cluster Validity Index.

# Examples

```julia
# Import the package
using ClusterValidityIndices
# Construct a DB module
my_cvi = DB()
```

$(local_references)
"""
function DB()
    DB(
        LabelMap(),                             # label_map
        0,                                      # dim
        0,                                      # n_samples
        Vector{Float}(undef, 0),                # mu
        Matrix{Float}(undef, 0, 0),             # D
        CVIExpandVector{Float}(undef, 0),       # S
        CVIElasticParams(),                     # params
        0,                                      # n_clusters
        0.0,                                    # criterion_value
    )
end

# Incremental parameter update function
function param_inc!(cvi::DB, sample::RealVector, label::Integer)
    # Initialize the incremental update
    i_label = init_cvi_update!(cvi, sample, label)

    if i_label > cvi.n_clusters
        # Add a new cluster to the CVI
        add_cluster!(cvi, sample)
        S_new = 0.0
        if cvi.n_clusters == 1
            D_new = zeros(1, 1)
        else
            D_new = zeros(cvi.n_clusters, cvi.n_clusters)
            D_new[1:cvi.n_clusters - 1, 1:cvi.n_clusters - 1] = cvi.D
            d_column_new = zeros(cvi.n_clusters)
            for jx = 1:cvi.n_clusters - 1
                # d_column_new[jx] = sum((v_new - cvi.params.v[:, jx]) .^ 2)
                d_column_new[jx] = sum((sample - cvi.params.v[:, jx]) .^ 2)
            end
            D_new[:, i_label] = d_column_new
            D_new[i_label, :] = transpose(d_column_new)
        end
        # Expand the parameters for a new cluster
        expand_strategy_1d!(cvi.S, S_new)
        cvi.D = D_new
    else
        n_new = cvi.params.n[i_label] + 1
        v_new = update_mean(cvi.params.v[:, i_label], sample, n_new)
        delta_v = cvi.params.v[:, i_label] - v_new
        diff_x_v = sample - v_new
        CP_new = (
            cvi.params.CP[i_label]
            + dot(diff_x_v, diff_x_v)
            + cvi.params.n[i_label] * dot(delta_v, delta_v)
            + 2 * dot(delta_v, cvi.params.G[:, i_label])
        )
        G_new = (
            cvi.params.G[:, i_label]
            + diff_x_v
            + cvi.params.n[i_label] * delta_v
        )
        S_new = CP_new / n_new
        d_column_new = zeros(cvi.n_clusters)
        for jx = 1:cvi.n_clusters
            # Skip the current i_label index
            if jx == i_label
                continue
            end
            d_column_new[jx] = sum((v_new - cvi.params.v[:, jx]) .^ 2)
        end
        # Update parameters
        update_params!(cvi.params, i_label, n_new, CP_new, v_new, G_new)
        cvi.S[i_label] = S_new
        cvi.D[:, i_label] = d_column_new
        cvi.D[i_label, :] = transpose(d_column_new)
    end
end

# Batch parameter update function
function param_batch!(cvi::DB, data::RealMatrix, labels::IntegerVector)
    cvi.dim, cvi.n_samples = size(data)
    # Take the average across all samples, but cast to 1-D vector
    cvi.mu = mean(data, dims=2)[:]
    u = unique(labels)
    cvi.n_clusters = length(u)
    # Initialize the parameters with both correct dimensions
    cvi.params = CVIElasticParams(cvi.dim, cvi.n_clusters)
    cvi.D = zeros(cvi.n_clusters, cvi.n_clusters)
    cvi.S = zeros(cvi.n_clusters)
    for ix = 1:cvi.n_clusters
        subset = data[:, findall(x->x==u[ix], labels)]
        cvi.params.n[ix] = size(subset, 2)
        # cvi.params.v[1:cvi.dim, ix] = mean(subset, dims=2)
        cvi.params.v[:, ix] = mean(subset, dims=2)
        diff_x_v = subset - cvi.params.v[:, ix] * ones(1, cvi.params.n[ix])
        cvi.params.CP[ix] = sum(diff_x_v .^ 2)
        cvi.S[ix] = cvi.params.CP[ix] / cvi.params.n[ix]
    end
    for ix = 1 : (cvi.n_clusters - 1)
        for jx = ix + 1 : cvi.n_clusters
            cvi.D[jx, ix] = sum((cvi.params.v[:, ix] - cvi.params.v[:, jx]) .^ 2)
        end
    end
    cvi.D = cvi.D + transpose(cvi.D)
end

# Criterion value evaluation function
function evaluate!(cvi::DB)
    if cvi.n_clusters > 1
        R = zeros(cvi.n_clusters, cvi.n_clusters)
        for ix = 1:(cvi.n_clusters - 1)
            for jx = ix + 1 : cvi.n_clusters
                R[ix, jx] = (cvi.S[ix] + cvi.S[jx]) / cvi.D[ix, jx]
            end
        end
        R = R + transpose(R)
        cvi.criterion_value = sum(maximum(R, dims=2)) / cvi.n_clusters
    else
        cvi.criterion_value = 0
    end
end
