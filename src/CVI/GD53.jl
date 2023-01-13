"""
    GD53.jl

# DescriptionIndices
This is a Julia port of a MATLAB implementation of batch and incremental
Generalized Dunn's Index 53 (GD53) Cluster Validity Index.

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
The stateful information of the Generalized Dunn's Index 53 (GD53) Cluster Validity Index.

$(local_references)
"""
mutable struct GD53 <: CVI
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
Constructor for the Generalized Dunn's Index 53 (GD53) Cluster Validity Index.

# Examples

```julia
# Import the package
using ClusterValidityIndices
# Construct a GD53 module
my_cvi = GD53()
```

$(local_references)
"""
function GD53()
    GD53(
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
function param_inc!(cvi::GD53, sample::RealVector, label::Integer)
    # Initialize the incremental update
    i_label = init_cvi_update!(cvi, sample, label)

    if i_label > cvi.n_clusters
        # Add a new cluster to the CVI
        add_cluster!(cvi, sample)

        # Create D_new and replace D
        D_new = zeros(cvi.n_clusters, cvi.n_clusters)
        if cvi.n_clusters > 1
            D_new[1:cvi.n_clusters - 1, 1:cvi.n_clusters - 1] = cvi.D
            d_column_new = zeros(cvi.n_clusters)
            for jx = 1:cvi.n_clusters - 1
                # d_column_new[jx] = (CP_new + cvi.params.CP[jx]) / (n_new + cvi.params.n[jx])
                d_column_new[jx] = cvi.params.CP[jx] / (1 + cvi.params.n[jx])
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
        G_new = cvi.params.G[:, i_label] + diff_x_v + cvi.params.n[i_label] .* delta_v
        d_column_new = zeros(cvi.n_clusters)
        for jx = 1:cvi.n_clusters
            # Skip the current i_label index
            if jx == i_label
                continue
            end
            # d_column_new[jx] = sum((v_new - cvi.params.v[:, jx]).^2)
            d_column_new[jx] = (CP_new + cvi.params.CP[jx]) / (n_new + cvi.params.n[jx])
        end
        # Update parameters
        update_params!(cvi.params, i_label, n_new, CP_new, v_new, G_new)
        cvi.D[:, i_label] = d_column_new
        cvi.D[i_label, :] = transpose(d_column_new)
    end
end

# Batch parameter update function
function param_batch!(cvi::GD53, data::RealMatrix, labels::IntegerVector)
    cvi.dim, cvi.n_samples = size(data)
    # Take the average across all samples, but cast to 1-D vector
    cvi.mu = mean(data, dims=2)[:]
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
                (cvi.params.CP[ix] + cvi.params.CP[jx]) / (cvi.params.n[ix] + cvi.params.n[jx])
            )
        end
    end
    cvi.D = cvi.D + transpose(cvi.D)
end

# Criterion value evaluation function
function evaluate!(cvi::GD53)
    if cvi.n_clusters > 1
        intra = 2 * maximum(cvi.params.CP ./ cvi.params.n)
        # Between-group measure of separation/isolation
        inter = (
            minimum(cvi.D[triu(ones(Bool, cvi.n_clusters, cvi.n_clusters), 1)])
        )
        # GD53 index value
        cvi.criterion_value = inter/intra
    else
        cvi.criterion_value = 0.0
    end
end
