"""
    cSIL.jl

# Description
This is a Julia port of a MATLAB implementation of batch and incremental
Centroid-based Silhouette (cSIL) Cluster Validity Index.

# Authors
- MATLAB implementation: Leonardo Enzo Brito da Silva
- Julia port: Sasha Petrenko <sap625@mst.edu>

# References
[1] L. E. Brito da Silva, N. M. Melton, and D. C. Wunsch II, "Incremental
Cluster Validity Indices for Hard Partitions: Extensions  and  Comparative
Study," ArXiv  e-prints, Feb 2019, arXiv:1902.06711v1 [cs.LG].
[2] P. J. Rousseeuw, "Silhouettes: A graphical aid to the interpretation and
validation of cluster analysis," Journal of Computational and Applied
Mathematics, vol. 20, pp. 53-65, 1987.
[3] M. Rawashdeh and A. Ralescu, "Center-wise intra-inter silhouettes," in
Scalable Uncertainty Management, E. Hüllermeier, S. Link, T. Fober et al.,
Eds. Berlin, Heidelberg: Springer, 2012, pp. 406-419.
"""

# References string
local_references = """
# References
1. L. E. Brito da Silva, N. M. Melton, and D. C. Wunsch II, "Incremental Cluster Validity Indices for Hard Partitions: Extensions  and  Comparative Study," ArXiv  e-prints, Feb 2019, arXiv:1902.06711v1 [cs.LG].
2. P. J. Rousseeuw, "Silhouettes: A graphical aid to the interpretation and validation of cluster analysis," Journal of Computational and Applied Mathematics, vol. 20, pp. 53-65, 1987.
3. M. Rawashdeh and A. Ralescu, "Center-wise intra-inter silhouettes," in Scalable Uncertainty Management, E. Hüllermeier, S. Link, T. Fober et al., Eds. Berlin, Heidelberg: Springer, 2012, pp. 406-419.
"""

"""
The stateful information of the Centroid-based Silhouette (cSIL) Cluster Validity Index.

$(local_references)
"""
mutable struct cSIL <: CVI
    label_map::LabelMap
    dim::Int
    n_samples::Int
    mu::Vector{Float}                       # dim
    params::CVIElasticParams
    S::Matrix{Float}                        # n_clusters x n_clusters
    sil_coefs::Vector{Float}                # dim
    n_clusters::Int
    criterion_value::Float
end

"""
Constructor for the Centroid-based Silhouette (cSIL) Cluster Validity Index.

# Examples

```julia
# Import the package
using ClusterValidityIndices
# Construct a cSIL module
my_cvi = cSIL()
```

$(local_references)
"""
function cSIL()
    cSIL(
        LabelMap(),                             # label_map
        0,                                      # dim
        0,                                      # n_samples
        Vector{Float}(undef, 0),                # mu
        CVIElasticParams(),                     # params
        Matrix{Float}(undef, 0, 0),             # S
        Vector{Float}(undef, 0),                # sil_coefs
        0,                                      # n_clusters
        0.0                                     # criterion_value
    )
end

# Incremental parameter update function
function param_inc!(cvi::cSIL, sample::RealVector, label::Integer)
    # Initialize the incremental update
    i_label = init_cvi_update!(cvi, sample, label)

    if i_label > cvi.n_clusters
        # Add a new cluster to the CVI
        add_cluster!(cvi, sample, alt_CP=true)

        # Compute S_new
        if cvi.n_clusters == 1
            S_new = zeros(1,1)
        else
            S_new = zeros(cvi.n_clusters, cvi.n_clusters)
            S_new[1:cvi.n_clusters - 1, 1:cvi.n_clusters - 1] = cvi.S
            S_row_new = zeros(cvi.n_clusters)
            S_col_new = zeros(cvi.n_clusters)
            for cl = 1:cvi.n_clusters - 1
                # Column "bmu_temp" - D_new
                C = (
                    # CP_new
                    cvi.params.CP[cvi.n_clusters]
                    + dot(cvi.params.v[:, cl], cvi.params.v[:, cl])
                    # - 2 * dot(G_new, cvi.params.v[:, cl])
                    - 2 * dot(cvi.params.G[:, cvi.n_clusters], cvi.params.v[:, cl])
                )
                S_col_new[cl] = C
                # Row "bmu_temp" - E
                C = (
                    cvi.params.CP[cl]
                    # Replacing v_new with sample here due to equivalence
                    # + cvi.params.n[cl] * dot(v_new, v_new)
                    + cvi.params.n[cl] * dot(sample, sample)
                    # - 2 * dot(cvi.params.G[:, cl], v_new)
                    - 2 * dot(cvi.params.G[:, cl], sample)
                )
                S_row_new[cl] = C / cvi.params.n[cl]
            end
            # Column "ind_minus" - F
            S_col_new[i_label] = 0
            S_row_new[i_label] = S_col_new[i_label]
            S_new[:, i_label] = S_col_new
            S_new[i_label, :] = S_row_new
        end
        # Replace S
        cvi.S = S_new
    else
        n_new = cvi.params.n[i_label] + 1
        v_new = update_mean(cvi.params.v[:, i_label], sample, n_new)
        CP_new = cvi.params.CP[i_label] + dot(sample, sample)
        G_new = cvi.params.G[:, i_label] + sample
        # Compute S_new
        S_row_new = zeros(cvi.n_clusters)
        S_col_new = zeros(cvi.n_clusters)
        for cl = 1:cvi.n_clusters
            # Skip the i_label iteration
            if cl == i_label
                continue
            end
            # Column "bmu_temp" - D_new
            diff_x_v = sample - cvi.params.v[:, cl]
            C = (
                cvi.params.CP[i_label]
                + dot(diff_x_v, diff_x_v)
                + cvi.params.n[i_label] * dot(cvi.params.v[:, cl], cvi.params.v[:, cl])
                - 2 * dot(G_new, cvi.params.v[:, cl])
            )
            S_col_new[cl] = C / n_new
            # Row "bmu_temp" - E
            C = (
                cvi.params.CP[cl]
                + cvi.params.n[cl] * dot(v_new, v_new)
                - 2 * dot(cvi.params.G[:, cl], v_new)
            )
            S_row_new[cl] = C / cvi.params.n[cl]
        end
        # Column "ind_minus" - F
        diff_x_v = sample - v_new
        C = (
            cvi.params.CP[i_label]
            + dot(diff_x_v, diff_x_v)
            + cvi.params.n[i_label] * dot(v_new, v_new)
            - 2 * dot(cvi.params.G[:, i_label], v_new)
        )
        S_col_new[i_label] = C / n_new
        S_row_new[i_label] = S_col_new[i_label]
        # Update parameters
        update_params!(cvi.params, i_label, n_new, CP_new, v_new, G_new)
        cvi.S[:, i_label] = S_col_new
        cvi.S[i_label, :] = S_row_new
    end
end

# Batch parameter update function
function param_batch!(cvi::cSIL, data::RealMatrix, labels::IntegerVector)
    cvi.dim, cvi.n_samples = size(data)
    u = unique(labels)
    cvi.n_clusters = length(u)
    # Initialize the parameters with both correct dimensions
    cvi.params = CVIElasticParams(cvi.dim, cvi.n_clusters)
    cvi.S = zeros(cvi.n_clusters, cvi.n_clusters)
    D = zeros(cvi.n_samples, cvi.n_clusters)
    for ix = 1:cvi.n_clusters
        subset = data[:, findall(x->x==u[ix], labels)]
        cvi.params.n[ix] = size(subset, 2)
        cvi.params.v[:, ix] = mean(subset, dims=2)
        # Compute CP in case of switching back to incremental mode
        d_temp = (data - cvi.params.v[:, ix] * ones(1, cvi.n_samples)) .^ 2
        D[:, ix] = transpose(sum(d_temp, dims=1))
    end
    for ix = 1:cvi.n_clusters
        for jx = 1:cvi.n_clusters
            subset_ind = findall(x->x==u[jx], labels)
            cvi.S[ix, jx] = sum(D[subset_ind, ix]) / cvi.params.n[jx]
        end
    end
end

# Criterion value evaluation function
function evaluate!(cvi::cSIL)
    cvi.sil_coefs = zeros(cvi.n_clusters)
    if !isempty(cvi.S) && cvi.n_clusters > 1
        for ix = 1:cvi.n_clusters
            # Same cluster
            a = cvi.S[ix, ix]
            # Other clusters
            b = minimum(cvi.S[ix, 1:end .!= ix])
            cvi.sil_coefs[ix] = (b - a) / max(a, b)
        end
        # cSIL index value
        cvi.criterion_value = sum(cvi.sil_coefs) / cvi.n_clusters
    else
        cvi.criterion_value = 0.0
    end
end
