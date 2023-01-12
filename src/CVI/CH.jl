"""
    CH.jl

# Description
This is a Julia port of a MATLAB implementation of batch and incremental
Calinski-Harabasz (CH) Cluster Validity Index.

# Authors
MATLAB implementation: Leonardo Enzo Brito da Silva
Julia port: Sasha Petrenko <sap625@mst.edu>

# References
[1] L. E. Brito da Silva, N. M. Melton, and D. C. Wunsch II, "Incremental
Cluster Validity Indices for Hard Partitions: Extensions  and  Comparative
Study," ArXiv  e-prints, Feb 2019, arXiv:1902.06711v1 [cs.LG].
[2] T. Calinski and J. Harabasz, "A dendrite method for cluster analysis,"
Communications in Statistics, vol. 3, no. 1, pp. 1-27, 1974.
[3] M. Moshtaghi, J. C. Bezdek, S. M. Erfani, C. Leckie, and J. Bailey,
"Online Cluster Validity Indices for Streaming Data," ArXiv e-prints, 2018,
arXiv:1801.02937v1 [stat.ML]. [Online].
[4] M. Moshtaghi, J. C. Bezdek, S. M. Erfani, C. Leckie, J. Bailey, "Online
cluster validity indices for performance monitoring of streaming data clustering,"
Int. J. Intell. Syst., pp. 1-23, 2018.
"""

# References string
local_references = """
# References
1. L. E. Brito da Silva, N. M. Melton, and D. C. Wunsch II, "Incremental Cluster Validity Indices for Hard Partitions: Extensions  and  Comparative Study," ArXiv  e-prints, Feb 2019, arXiv:1902.06711v1 [cs.LG].
2. T. Calinski and J. Harabasz, "A dendrite method for cluster analysis," Communications in Statistics, vol. 3, no. 1, pp. 1-27, 1974.
3. M. Moshtaghi, J. C. Bezdek, S. M. Erfani, C. Leckie, and J. Bailey, "Online Cluster Validity Indices for Streaming Data," ArXiv e-prints, 2018, arXiv:1801.02937v1 [stat.ML]. [Online].
4. M. Moshtaghi, J. C. Bezdek, S. M. Erfani, C. Leckie, J. Bailey, "Online cluster validity indices for performance monitoring of streaming data clustering," Int. J. Intell. Syst., pp. 1-23, 2018.
"""

"""
The stateful information of the Calinski-Harabasz (CH) Cluster Validity Index

$(local_references)
"""
mutable struct CH <: CVI
    label_map::LabelMap
    dim::Int
    n_samples::Int
    mu::Vector{Float}               # dim
    SEP::Vector{Float}              # dim
    params::CVIElasticParams
    n_clusters::Int
    criterion_value::Float
end

"""
Constructor for the Calinski-Harabasz (CH) Cluster Validity Index.

# Examples

```julia
# Import the package
using ClusterValidityIndices
# Construct a CH module
my_cvi = CH()
```

$(local_references)
"""
function CH()
    CH(
        LabelMap(),                             # label_map
        0,                                      # dim
        0,                                      # n_samples
        Vector{Float}(undef, 0),                # mu
        Vector{Float}(undef, 0),                # SEP
        CVIElasticParams(0),
        0,                                      # n_clusters
        0.0                                     # criterion_value
    )
end

# Incremental parameter update function
function param_inc!(cvi::CH, sample::RealVector, label::Integer)
    # Initialize the incremental update
    i_label = init_cvi_inc!(cvi, sample, label)

    if i_label > cvi.n_clusters
        n_new = 1
        v_new = sample
        CP_new = 0.0
        G_new = zeros(cvi.dim)
        # Expand the parameters for a new cluster
        cvi.n_clusters += 1
        expand_params!(cvi.params, n_new, CP_new, v_new, G_new)
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
            # + cvi.params.n[i_label] .* delta_v
        )
        # Update parameters
        update_params!(cvi.params, i_label, n_new, CP_new, v_new, G_new)
    end
    # Compute the separation
    cvi.SEP = zeros(cvi.n_clusters)
    for ix = 1:cvi.n_clusters
        cvi.SEP[ix] = cvi.params.n[ix] * sum((cvi.params.v[:, ix] - cvi.mu) .^ 2)
    end
end

# Batch parameter update function
function param_batch!(cvi::CH, data::RealMatrix, labels::IntegerVector)
    cvi.dim, cvi.n_samples = size(data)
    # Take the average across all samples, but cast to 1-D vector
    cvi.mu = mean(data, dims=2)[:]
    u = unique(labels)
    cvi.n_clusters = length(u)
    # Initialize the parameters with both correct dimensions
    cvi.params = CVIElasticParams(cvi.dim, cvi.n_clusters)
    cvi.SEP = zeros(cvi.n_clusters)
    for ix = 1:cvi.n_clusters
        subset = data[:, findall(x->x==u[ix], labels)]
        cvi.params.n[ix] = size(subset, 2)
        cvi.params.v[1:cvi.dim, ix] = mean(subset, dims=2)
        diff_x_v = subset - cvi.params.v[:, ix] * ones(1, cvi.params.n[ix])
        cvi.params.CP[ix] = sum(diff_x_v .^ 2)
        cvi.SEP[ix] = cvi.params.n[ix] * sum((cvi.params.v[:, ix] - cvi.mu) .^ 2);
    end
end

# Criterion value evaluation function
function evaluate!(cvi::CH)
    # Within group sum of squares
    WGSS = sum(cvi.params.CP)
    if cvi.n_clusters > 1
        # Between groups sum of squares
        BGSS = sum(cvi.SEP)
        # CH index value
        cvi.criterion_value = (
            (BGSS / WGSS)
            * ((cvi.n_samples - cvi.n_clusters) / (cvi.n_clusters - 1))
        )
    else
        cvi.criterion_value = 0.0
    end
end
