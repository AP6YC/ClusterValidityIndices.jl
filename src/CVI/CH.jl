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
    n::CVIExpandVector{Int}         # dim
    v::CVIExpandMatrix{Float}       # dim x n_clusters
    CP::CVIExpandVector{Float}      # dim
    G::CVIExpandMatrix{Float}       # dim x n_clusters
    BGSS::Float
    WGSS::Float
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
        CVIExpandVector{Int}(undef, 0),         # n
        CVIExpandMatrix{Float}(undef, 0, 0),    # v
        CVIExpandVector{Float}(undef, 0),       # CP
        CVIExpandMatrix{Float}(undef, 0, 0),    # G
        0.0,                                    # BGSS
        0.0,                                    # WGSS
        0,                                      # n_clusters
        0.0                                     # criterion_value
    )
end

# Setup function
function setup!(cvi::CH, sample::RealVector)
    # Get the feature dimension
    cvi.dim = length(sample)
    # Initialize the augmenting 2-D arrays with the correct feature dimension
    # NOTE: R is emptied and calculated in evaluate!, so it is not defined here
    cvi.v = CVIExpandMatrix{Float}(undef, cvi.dim, 0)
    cvi.G = CVIExpandMatrix{Float}(undef, cvi.dim, 0)
end

# Incremental parameter update function
function param_inc!(cvi::CH, sample::RealVector, label::Integer)
    # Get the internal label
    i_label = get_internal_label!(cvi.label_map, label)

    n_samples_new = cvi.n_samples + 1
    if isempty(cvi.mu)
        mu_new = sample
        setup!(cvi, sample)
    else
        mu_new = (
            (1 - 1/n_samples_new) .* cvi.mu + (1 / n_samples_new) .* sample
        )
    end

    if i_label > cvi.n_clusters
        n_new = 1
        v_new = sample
        CP_new = 0.0
        G_new = zeros(cvi.dim)
        # Update 1-D parameters with a push
        cvi.n_clusters += 1
        expand_strategy_1d!(cvi.CP, CP_new)
        expand_strategy_1d!(cvi.n, n_new)
        # Update 2-D parameters with appending and reassignment
        expand_strategy_2d!(cvi.v, v_new)
        expand_strategy_2d!(cvi.G, G_new)
    else
        n_new = cvi.n[i_label] + 1
        v_new = (
            (1 - 1/n_new) .* cvi.v[:, i_label] + (1 / n_new) .* sample
        )
        delta_v = cvi.v[:, i_label] - v_new
        diff_x_v = sample .- v_new
        CP_new = (
            cvi.CP[i_label]
            + dot(diff_x_v, diff_x_v)
            + cvi.n[i_label] * dot(delta_v, delta_v)
            + 2 * dot(delta_v, cvi.G[:, i_label])
        )
        G_new = (
            cvi.G[:, i_label]
            + diff_x_v
            + cvi.n[i_label] .* delta_v
        )
        # Update parameters
        cvi.n[i_label] = n_new
        cvi.v[:, i_label] = v_new
        cvi.CP[i_label] = CP_new
        cvi.G[:, i_label] = G_new
    end
    cvi.n_samples = n_samples_new
    cvi.mu = mu_new
    cvi.SEP = (
        [cvi.n[ix] * sum((cvi.v[:, ix] - cvi.mu) .^ 2) for ix = 1:cvi.n_clusters]
    )
end

# Batch parameter update function
function param_batch!(cvi::CH, data::RealMatrix, labels::IntegerVector)
    cvi.dim, cvi.n_samples = size(data)
    # Take the average across all samples, but cast to 1-D vector
    cvi.mu = mean(data, dims=2)[:]
    u = unique(labels)
    cvi.n_clusters = length(u)
    cvi.n = zeros(Integer, cvi.n_clusters)
    cvi.v = zeros(cvi.dim, cvi.n_clusters)
    cvi.CP = zeros(cvi.n_clusters)
    cvi.SEP = zeros(cvi.n_clusters)
    for ix = 1:cvi.n_clusters
        subset = data[:, findall(x->x==u[ix], labels)]
        cvi.n[ix] = size(subset, 2)
        cvi.v[1:cvi.dim, ix] = mean(subset, dims=2)
        diff_x_v = subset - cvi.v[:, ix] * ones(1, cvi.n[ix])
        cvi.CP[ix] = sum(diff_x_v .^ 2)
        cvi.SEP[ix] = cvi.n[ix] * sum((cvi.v[:, ix] - cvi.mu) .^ 2);
    end
end

# Criterion value evaluation function
function evaluate!(cvi::CH)
    # Within group sum of scatters
    cvi.WGSS = sum(cvi.CP)
    if cvi.n_clusters > 1
        # Between groups sum of scatters
        cvi.BGSS = sum(cvi.SEP)
        # CH index value
        cvi.criterion_value = (
            (cvi.BGSS / cvi.WGSS)
            * ((cvi.n_samples - cvi.n_clusters) / (cvi.n_clusters - 1))
        )
    else
        cvi.BGSS = 0.0
        cvi.criterion_value = 0.0
    end
end
