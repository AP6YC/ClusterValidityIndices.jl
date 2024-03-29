"""
    XB.jl

# Description
This is a Julia port of a MATLAB implementation of batch and incremental
Xie-Beni (XB) Cluster Validity Index.

# Authors
- MATLAB implementation: Leonardo Enzo Brito da Silva
- Julia port: Sasha Petrenko <sap625@mst.edu>

# References
[1] X. L. Xie and G. Beni, "A Validity Measure for Fuzzy Clustering," IEEE
Transactions on Pattern Analysis and Machine Intelligence, vol. 13, no. 8,
pp. 841-847, 1991.
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
1. X. L. Xie and G. Beni, "A Validity Measure for Fuzzy Clustering," IEEE Transactions on Pattern Analysis and Machine Intelligence, vol. 13, no. 8, pp. 841-847, 1991.
2. M. Moshtaghi, J. C. Bezdek, S. M. Erfani, C. Leckie, and J. Bailey, "Online Cluster Validity Indices for Streaming Data," ArXiv e-prints, 2018, arXiv:1801.02937v1 [stat.ML]. [Online].
3. M. Moshtaghi, J. C. Bezdek, S. M. Erfani, C. Leckie, J. Bailey, "Online cluster validity indices for performance monitoring of streaming data clustering," Int. J. Intell. Syst., pp. 1-23, 2018.
"""

"""
The stateful information of the Xie-Beni (XB) Cluster Validity Index.

$(local_references)
"""
mutable struct XB <: CVI
    label_map::LabelMap
    dim::Int
    n_samples::Int
    mu::Vector{Float}                       # dim
    D::Matrix{Float}                        # n_clusters x n_clusters
    params::CVIElasticParams
    n_clusters::Int
    criterion_value::Float
end

"""
Constructor for the Xie-Beni (XB) Cluster Validity Index.

# Examples

```julia
# Import the package
using ClusterValidityIndices
# Construct a XB module
my_cvi = XB()
```

$(local_references)
"""
function XB()
    XB(
        LabelMap(),                             # label_map
        0,                                      # dim
        0,                                      # n_samples
        Vector{Float}(undef, 0),                # mu
        Matrix{Float}(undef, 0, 0),             # D
        CVIElasticParams(),                     # params
        0,                                      # n_clusters
        0.0                                     # criterion_value
    )
end

# Incremental parameter update function
function param_inc!(cvi::XB, sample::RealVector, label::Integer)
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
            # println(d_column_new)
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
        d_column_new = zeros(cvi.n_clusters)
        for jx = 1:cvi.n_clusters
            if jx == i_label
                continue
            end
            d_column_new[jx] = sum((v_new - cvi.params.v[:, jx]) .^ 2)
        end
        # Update parameters
        update_params!(cvi.params, i_label, n_new, CP_new, v_new, G_new)
        cvi.D[:, i_label] = d_column_new
        cvi.D[i_label, :] = transpose(d_column_new)
    end
end

# Incremental parameter update function
function param_batch!(cvi::XB, data::RealMatrix, labels::IntegerVector)
    # Initialize the batch update
    u = init_cvi_update!(cvi, data, labels)
    cvi.D = zeros(cvi.n_clusters, cvi.n_clusters)
    for ix = 1:cvi.n_clusters
        subset = data[:, findall(x->x==u[ix], labels)]
        cvi.params.n[ix] = size(subset, 2)
        cvi.params.v[1:cvi.dim, ix] = mean(subset, dims=2)
        diff_x_v = subset - cvi.params.v[:, ix] * ones(1, cvi.params.n[ix])
        cvi.params.CP[ix] = sum(diff_x_v .^ 2)
    end
    for ix = 1 : (cvi.n_clusters - 1)
        for jx = ix + 1 : cvi.n_clusters
            cvi.D[jx, ix] = (
                sum((cvi.params.v[:, ix] - cvi.params.v[:, jx]) .^ 2)
            )
        end
    end
    cvi.D = cvi.D + transpose(cvi.D)
end

# Criterion value evaluation function
function evaluate!(cvi::XB)
    if cvi.n_clusters > 1
        WGSS = sum(cvi.params.CP)
        # Assume a symmetric dimension
        dim = size(cvi.D)[1]
        # Get the values from D as the upper triangular offset from the diagonal
        # values = zeros[cvi.D[i, j] for i = 1:dim, j=1:dim if j > i]
        values = [cvi.D[i, j] for i = 1:dim, j=1:dim if j > i]
        # SEP is the minimum of these unique D values
        SEP = minimum(values)
        # Criterion value is
        cvi.criterion_value = WGSS / (cvi.n_samples * SEP)
    else
        # SEP = 0.0
        cvi.criterion_value = 0.0
    end
end
