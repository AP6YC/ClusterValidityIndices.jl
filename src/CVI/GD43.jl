"""
    GD43.jl

# Description
This is a Julia port of a MATLAB implementation of batch and incremental
Generalized Dunn's Index 43 (GD43) Cluster Validity Index.

# Authors
- MATLAB implementation: Leonardo Enzo Brito da Silva
- Julia port: Sasha Petrenko <sap625@mst.edu>

# References
[1] A. Ibrahim, J. M. Keller, and J. C. Bezdek, "Evaluating Evolving Structure
in Streaming Data With Modified Dunn's Indices," IEEE Transactions on Emerging
Topics in Computational Intelligence, pp. 1-12, 2019.
[2] M. Moshtaghi, J. C. Bezdek, S. M. Erfani, C. Leckie, and J. Bailey,
"Online Cluster Validity Indices for Streaming Data," ArXiv e-prints, 2018,
arXiv:1801.02937v1 [stat.ML].
[3] M. Moshtaghi, J. C. Bezdek, S. M. Erfani, C. Leckie, J. Bailey, "Online
cluster validity indices for performance monitoring of streaming data clustering,"
Int. J. Intell. Syst., pp. 1-23, 2018.
[4] J. C. Dunn, "A fuzzy relative of the ISODATA process and its use in detecting
compact well-separated clusters," J. Cybern., vol. 3, no. 3 , pp. 32-57, 1973.
[5] J. C. Bezdek and N. R. Pal, "Some new indexes of cluster validity," IEEE
Trans. Syst., Man, and Cybern., vol. 28, no. 3, pp. 301-315, Jun. 1998.
"""

# References string
local_references = """
# References
1. A. Ibrahim, J. M. Keller, and J. C. Bezdek, "Evaluating Evolving Structure in Streaming Data With Modified Dunn's Indices," IEEE Transactions on Emerging Topics in Computational Intelligence, pp. 1-12, 2019.
2. M. Moshtaghi, J. C. Bezdek, S. M. Erfani, C. Leckie, and J. Bailey, "Online Cluster Validity Indices for Streaming Data," ArXiv e-prints, 2018, arXiv:1801.02937v1 [stat.ML].
3. M. Moshtaghi, J. C. Bezdek, S. M. Erfani, C. Leckie, J. Bailey, "Online cluster validity indices for performance monitoring of streaming data clustering," Int. J. Intell. Syst., pp. 1-23, 2018.
4. J. C. Dunn, "A fuzzy relative of the ISODATA process and its use in detecting compact well-separated clusters," J. Cybern., vol. 3, no. 3 , pp. 32-57, 1973.
5. J. C. Bezdek and N. R. Pal, "Some new indexes of cluster validity," IEEE Trans. Syst., Man, and Cybern., vol. 28, no. 3, pp. 301-315, Jun. 1998.
"""

"""
The stateful information of the Generalized Dunn's Index 43 (GD43) Cluster Validity Index.

$(local_references)
"""
mutable struct GD43 <: CVI
    label_map::LabelMap
    dim::Int
    n_samples::Int
    mu::Vector{Float}                   # dim
    D::Matrix{Float}                    # n_clusters x n_clusters
    params::CVIElasticParams
    n_clusters::Int
    criterion_value::Float
end

"""
Constructor for the Generalized Dunn's Index 43 (GD43) Cluster Validity Index.

# Examples

```julia
# Import the package
using ClusterValidityIndices
# Construct a GD43 module
my_cvi = GD43()
```

$(local_references)
"""
function GD43()
    GD43(
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
function param_inc!(cvi::GD43, sample::RealVector, label::Integer)
    # Initialize the incremental update
    i_label = init_cvi_update!(cvi, sample, label)

    if i_label > cvi.n_clusters
        n_new = 1
        v_new = sample
        CP_new = 0.0
        G_new = zeros(cvi.dim)
        if cvi.n_clusters == 0
            D_new = zeros(1,1)
        else
            D_new = zeros(cvi.n_clusters + 1, cvi.n_clusters + 1)
            D_new[1:cvi.n_clusters, 1:cvi.n_clusters] = cvi.D
            d_column_new = zeros(cvi.n_clusters + 1)
            for jx = 1:cvi.n_clusters
                d_column_new[jx] = sqrt(sum((v_new - cvi.params.v[:, jx]) .^ 2))
            end
            D_new[:, i_label] = d_column_new
            D_new[i_label, :] = transpose(d_column_new)
        end
        # Expand the parameters for a new cluster
        cvi.n_clusters += 1
        expand_params!(cvi.params, n_new, CP_new, v_new, G_new)
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
            # Skip the current i_label index
            if jx == i_label
                continue
            end
            d_column_new[jx] = sqrt(sum((v_new - cvi.params.v[:, jx]) .^ 2))
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

# Batch parameter update function
function param_batch!(cvi::GD43, data::RealMatrix, labels::IntegerVector)
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
                sqrt(sum((cvi.params.v[:, ix] - cvi.params.v[:, jx]) .^ 2))
            )
        end
    end
    cvi.D = cvi.D + transpose(cvi.D)
end

# Criterion value evaluation function
function evaluate!(cvi::GD43)
    if cvi.n_clusters > 1
        intra = 2 * maximum(cvi.params.CP ./ cvi.params.n)
        # Between-group measure of separation/isolation
        inter = (
            minimum(cvi.D[triu(ones(Bool, cvi.n_clusters, cvi.n_clusters), 1)])
            # minimum(triu(cvi.D, 1))
        )
        # GD43 index value
        cvi.criterion_value = inter / intra
    else
        cvi.criterion_value = 0.0
    end
end
