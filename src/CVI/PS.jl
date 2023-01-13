"""
    PS.jl

# Description
This is a Julia port of a MATLAB implementation of batch and incremental
Partition Separation (PS) Cluster Validity Index.

# Authors
- MATLAB implementation: Leonardo Enzo Brito da Silva
- Julia port: Sasha Petrenko <sap625@mst.edu>

# References
[1] Miin-Shen Yang and Kuo-Lung Wu, "A new validity index for fuzzy clustering,"
10th IEEE International Conference on Fuzzy Systems. (Cat. No.01CH37297), Melbourne,
Victoria, Australia, 2001, pp. 89-92, vol.1.
[2] E. Lughofer, "Extensions of vector quantization for incremental clustering," Pattern
Recognit., vol. 41, no. 3, pp. 995-1011, 2008.
"""

# References string
local_references = """
# References
1. Miin-Shen Yang and Kuo-Lung Wu, "A new validity index for fuzzy clustering," 10th IEEE International Conference on Fuzzy Systems. (Cat. No.01CH37297), Melbourne, Victoria, Australia, 2001, pp. 89-92, vol.1.
2. E. Lughofer, "Extensions of vector quantization for incremental clustering," Pattern Recognit., vol. 41, no. 3, pp. 995-1011, 2008.
"""

"""
The stateful information of the Partition Separation (PS) Cluster Validity Index.

$(local_references)
"""
mutable struct PS <: CVI
    label_map::LabelMap
    dim::Int
    n_samples::Int
    mu::Vector{Float}
    params::CVIElasticParams
    D::Matrix{Float}                    # n_clusters x n_clusters
    n_clusters::Int
    criterion_value::Float
end

"""
Constructor for the Partition Separation (PS) Cluster Validity Index.

# Examples

```julia
# Import the package
using ClusterValidityIndices
# Construct a PS module
my_cvi = PS()
```

$(local_references)
"""
function PS()
    PS(
        LabelMap(),                             # label_map
        0,                                      # dim
        0,                                      # n_samples
        Vector{Float}(undef, 0),                # mu
        CVIElasticParams(),                     # params
        Matrix{Float}(undef, 0, 0),             # D
        0,                                      # n_clusters
        0.0                                     # criterion_value
    )
end

# Incremental parameter update function
function param_inc!(cvi::PS, sample::RealVector, label::Integer)
    # Initialize the incremental update
    i_label = init_cvi_update!(cvi, sample, label)

    if i_label > cvi.n_clusters
        # Add a new cluster to the CVI
        add_cluster!(cvi, sample)
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
        cvi.D = D_new
    else
        n_new = cvi.params.n[i_label] + 1
        v_new = update_mean(cvi.params.v[:, i_label], sample, n_new)
        d_column_new = zeros(cvi.n_clusters)
        for jx = 1:cvi.n_clusters
            if jx == i_label
                continue
            end
            d_column_new[jx] = sum((v_new - cvi.params.v[:, jx]) .^ 2)
        end
        # Update parameters
        cvi.params.n[i_label] = n_new
        cvi.params.v[:, i_label] = v_new
        cvi.D[:, i_label] = d_column_new
        cvi.D[i_label, :] = transpose(d_column_new)
    end
end

# Batch parameter update function
function param_batch!(cvi::PS, data::RealMatrix, labels::IntegerVector)
    # Initialize the batch update
    u = init_cvi_update!(cvi, data, labels)
    cvi.D = zeros(cvi.n_clusters, cvi.n_clusters)
    for ix = 1:cvi.n_clusters
        subset = data[:, findall(x->x==u[ix], labels)]
        cvi.params.n[ix] = size(subset, 2)
        cvi.params.v[1:cvi.dim, ix] = mean(subset, dims=2)
    end
    for ix = 1 : (cvi.n_clusters - 1)
        for jx = ix + 1 : cvi.n_clusters
            cvi.D[jx, ix] = sum((cvi.params.v[:, ix] - cvi.params.v[:, jx]) .^ 2)
        end
    end
    cvi.D = cvi.D + transpose(cvi.D)
end

# Criterion value evaluation function
function evaluate!(cvi::PS)
    if cvi.n_clusters > 1
        v_bar = vec(mean(cvi.params.v, dims=2))
        beta_t = 0.0
        PS_i = zeros(cvi.n_clusters)
        for ix = 1:cvi.n_clusters
            delta_v = cvi.params.v[:, ix] - v_bar
            beta_t += dot(delta_v, delta_v)
        end
        beta_t /= cvi.n_clusters
        n_max = maximum(cvi.params.n)
        for ix = 1:cvi.n_clusters
            d = cvi.D[:, ix]
            # Exclude the category itself in the minimum calculation
            d[ix] = Inf
            PS_i[ix] = (
                (cvi.params.n[ix] / n_max)
                - exp(-minimum(d) / beta_t)
            )
        end
        cvi.criterion_value = sum(PS_i)
    end
end
