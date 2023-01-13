"""
    WB.jl

# Description
This is a Julia port of a MATLAB implementation of batch and incremental
WB-Index (WB) Cluster Validity Index.

# Authors
- MATLAB implementation: Leonardo Enzo Brito da Silva
- Julia port: Sasha Petrenko <sap625@mst.edu>

# References
[1] L. E. Brito da Silva, N. M. Melton, and D. C. Wunsch II, "Incremental
Cluster Validity Indices for Hard Partitions: Extensions  and  Comparative
Study," ArXiv  e-prints, Feb 2019, arXiv:1902.06711v1 [cs.LG].
[2] Q. Zhao, M. Xu, and P. Franti, "Sum-of-Squares Based Cluster Validity
Index and Significance Analysis," in Adaptive and Natural Computing Algorithms,
M. Kolehmainen, P. Toivanen, and B. Beliczynski, Eds. Berlin, Heidelberg:
Springer Berlin Heidelberg, 2009, pp. 313-322.
[3] Q. Zhao and P. Franti, "WB-index: A sum-of-squares based index for
cluster validity," Data Knowledge Engineering, vol. 92, pp. 77-89, 2014.
[4] M. Moshtaghi, J. C. Bezdek, S. M. Erfani, C. Leckie, and J. Bailey,
"Online Cluster Validity Indices for Streaming Data," ArXiv e-prints, 2018,
arXiv:1801.02937v1 [stat.ML].
[5] M. Moshtaghi, J. C. Bezdek, S. M. Erfani, C. Leckie, J. Bailey, "Online
cluster validity indices for performance monitoring of streaming data clustering,"
Int. J. Intell. Syst., pp. 1-23, 2018.
"""

# References string
local_references = """
# References
1. L. E. Brito da Silva, N. M. Melton, and D. C. Wunsch II, "Incremental Cluster Validity Indices for Hard Partitions: Extensions  and  Comparative Study," ArXiv  e-prints, Feb 2019, arXiv:1902.06711v1 [cs.LG].
2. Q. Zhao, M. Xu, and P. Franti, "Sum-of-Squares Based Cluster Validity Index and Significance Analysis," in Adaptive and Natural Computing Algorithms, M. Kolehmainen, P. Toivanen, and B. Beliczynski, Eds. Berlin, Heidelberg: Springer Berlin Heidelberg, 2009, pp. 313-322.
3. Q. Zhao and P. Franti, "WB-index: A sum-of-squares based index for cluster validity," Data Knowledge Engineering, vol. 92, pp. 77-89, 2014.
4. M. Moshtaghi, J. C. Bezdek, S. M. Erfani, C. Leckie, and J. Bailey, "Online Cluster Validity Indices for Streaming Data," ArXiv e-prints, 2018, arXiv:1801.02937v1 [stat.ML].
5. M. Moshtaghi, J. C. Bezdek, S. M. Erfani, C. Leckie, J. Bailey, "Online cluster validity indices for performance monitoring of streaming data clustering," Int. J. Intell. Syst., pp. 1-23, 2018.
"""

"""
The stateful information of the WB-Index (WB) Cluster Validity Index.

$(local_references)
"""
mutable struct WB <: CVI
    label_map::LabelMap
    dim::Int
    n_samples::Int
    mu::Vector{Float}                   # dim
    params::CVIElasticParams
    n_clusters::Int
    criterion_value::Float
end

"""
Constructor for the WB-Index (WB) Cluster Validity Index.

# Examples

```julia
# Import the package
using ClusterValidityIndices
# Construct a WB module
my_cvi = WB()
```

$(local_references)
"""
function WB()
    WB(
        LabelMap(),                             # label_map
        0,                                      # dim
        0,                                      # n_samples
        Vector{Float}(undef, 0),                # mu
        CVIElasticParams(),                     # params
        0,                                      # n_clusters
        0.0                                     # criterion_value
    )
end

# Incremental parameter update function
function param_inc!(cvi::WB, sample::RealVector, label::Integer)
    # Initialize the incremental update
    i_label = init_cvi_update!(cvi, sample, label)

    if i_label > cvi.n_clusters
        # Add a new cluster to the CVI
        add_cluster!(cvi, sample)
    else
        n_new = cvi.params.n[i_label] + 1
        v_new = update_mean(cvi.params.v[:, i_label], sample, n_new)
        delta_v = cvi.params.v[:, i_label] - v_new
        diff_x_v = sample - v_new
        CP_new = (
            cvi.params.CP[i_label]
            + transpose(diff_x_v) * diff_x_v
            + cvi.params.n[i_label] * transpose(delta_v) * delta_v
            + 2 * transpose(delta_v) * cvi.params.G[:, i_label]
        )
        G_new = (
            cvi.params.G[:, i_label]
            + diff_x_v
            + cvi.params.n[i_label] * delta_v
        )
        # Update parameters
        update_params!(cvi.params, i_label, n_new, CP_new, v_new, G_new)
    end
    # Compute the new separation
    for ix = 1:cvi.n_clusters
        cvi.params.SEP[ix] = cvi.params.n[ix] * sum((cvi.params.v[:, ix] - cvi.mu) .^ 2)
    end
end

# Batch parameter update function
function param_batch!(cvi::WB, data::RealMatrix, labels::IntegerVector)
    # Initialize the batch update
    u = init_cvi_update!(cvi, data, labels)
    for ix = 1:cvi.n_clusters
        subset = data[:, findall(x->x==u[ix], labels)]
        cvi.params.n[ix] = size(subset, 2)
        cvi.params.v[1:cvi.dim, ix] = mean(subset, dims=2)
        diff_x_v = subset - cvi.params.v[:, ix] * ones(1, cvi.params.n[ix])
        cvi.params.CP[ix] = sum(diff_x_v .^ 2)
        cvi.params.SEP[ix] = cvi.params.n[ix] * sum((cvi.params.v[:, ix] - cvi.mu) .^ 2);
    end
end

# Criterion value evaluation function
function evaluate!(cvi::WB)
    # Within group sum of scatters
    if cvi.n_clusters > 1
        WGSS = sum(cvi.params.CP)
        # Between groups sum of scatters
        BGSS = sum(cvi.params.SEP)
        # WB index value
        cvi.criterion_value = (WGSS / BGSS) * cvi.n_clusters
    else
        # BGSS = 0.0
        cvi.criterion_value = 0.0;
    end
end
