"""
    XB.jl

# Description
This is a Julia port of a MATLAB implementation of batch and incremental
Xie-Beni (XB) Cluster Validity Index.

# Authors
MATLAB implementation: Leonardo Enzo Brito da Silva
Julia port: Sasha Petrenko <sap625@mst.edu>

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
    SEP::Float
    WGSS::Float
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
        CVIElasticParams(0),                    # params
        0.0,                                    # SEP
        0.0,                                    # WGSS
        0,                                      # n_clusters
        0.0                                     # criterion_value
    )
end

# Incremental parameter update function
function param_inc!(cvi::XB, sample::RealVector, label::Integer)
    # Initialize the incremental update
    i_label = init_cvi_inc!(cvi, sample, label)

    if i_label > cvi.n_clusters
        n_new = 1
        v_new = sample
        CP_new = 0.0
        G_new = zeros(cvi.dim)
        if cvi.n_clusters == 0
            D_new = zeros(1, 1)
        else
            D_new = zeros(cvi.n_clusters + 1, cvi.n_clusters + 1)
            D_new[1:cvi.n_clusters, 1:cvi.n_clusters] = cvi.D
            d_column_new = zeros(cvi.n_clusters + 1)
            # println(d_column_new)
            for jx = 1:cvi.n_clusters
                d_column_new[jx] = sum((v_new - cvi.params.v[:, jx]) .^ 2)
            end
            D_new[:, i_label] = d_column_new
            D_new[i_label, :] = transpose(d_column_new)
        end
        # Update 1-D parameters with a push
        cvi.n_clusters += 1
        expand_strategy_1d!(cvi.params.CP, CP_new)
        expand_strategy_1d!(cvi.params.n, n_new)
        # Update 2-D parameters with appending and reassignment
        expand_strategy_2d!(cvi.params.v, v_new)
        expand_strategy_2d!(cvi.params.G, G_new)
        cvi.D = D_new
    else
        n_new = cvi.params.n[i_label] + 1
        v_new = (
            (1 - 1/n_new) .* cvi.params.v[:, i_label]
            + (1/n_new) .* sample
        )
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
            + cvi.params.n[i_label] .* delta_v
        )
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
        cvi.params.CP[i_label] = CP_new
        cvi.params.G[:, i_label] = G_new
        cvi.D[:, i_label] = d_column_new
        cvi.D[i_label, :] = transpose(d_column_new)
    end
end

# Incremental parameter update function
function param_batch!(cvi::XB, data::RealMatrix, labels::IntegerVector)
    cvi.dim, cvi.n_samples = size(data)
    # Take the average across all samples, but cast to 1-D vector
    cvi.mu = mean(data, dims=2)[:]
    # u = findfirst.(isequal.(unique(labels)), [labels])
    u = unique(labels)
    cvi.n_clusters = length(u)
    # Initialize the parameters with both correct dimensions
    cvi.params = CVIElasticParams(cvi.dim, cvi.n_clusters)
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
        cvi.WGSS = sum(cvi.params.CP)
        # Assume a symmetric dimension
        dim = size(cvi.D)[1]
        # Get the values from D as the upper triangular offset from the diagonal
        # values = zeros[cvi.D[i, j] for i = 1:dim, j=1:dim if j > i]
        values = [cvi.D[i, j] for i = 1:dim, j=1:dim if j > i]
        # SEP is the minimum of these unique D values
        cvi.SEP = minimum(values)
        # Criterion value is
        cvi.criterion_value = cvi.WGSS / (cvi.n_samples * cvi.SEP)
    else
        cvi.SEP = 0.0
        cvi.criterion_value = 0.0
    end
end
