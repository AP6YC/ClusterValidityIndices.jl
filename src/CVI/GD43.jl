"""
    GD43.jl

This is a Julia port of a MATLAB implementation of batch and incremental
Generalized Dunn's Index 43 (GD43) Cluster Validity Index.

Authors:
MATLAB implementation: Leonardo Enzo Brito da Silva
Julia port: Sasha Petrenko <sap625@mst.edu>

REFERENCES
[1] A. Ibrahim, J. M. Keller, and J. C. Bezdek, "Evaluating Evolving Structure
in Streaming Data With Modified Dunn's Indices," IEEE Transactions on Emerging
Topics in Computational Intelligence, pp. 1–12, 2019.
[2] M. Moshtaghi, J. C. Bezdek, S. M. Erfani, C. Leckie, and J. Bailey,
"Online Cluster Validity Indices for Streaming Data," ArXiv e-prints, 2018,
arXiv:1801.02937v1 [stat.ML].
[3] M. Moshtaghi, J. C. Bezdek, S. M. Erfani, C. Leckie, J. Bailey, "Online
cluster validity indices for performance monitoring of streaming data clustering,"
Int. J. Intell. Syst., pp. 1–23, 2018.
[4] J. C. Dunn, "A fuzzy relative of the ISODATA process and its use in detecting
compact well-separated clusters," J. Cybern., vol. 3, no. 3 , pp. 32–57, 1973.
[5] J. C. Bezdek and N. R. Pal, "Some new indexes of cluster validity," IEEE
Trans. Syst., Man, and Cybern., vol. 28, no. 3, pp. 301–315, Jun. 1998.

"""

using Statistics
using LinearAlgebra

"""
    GD43

The stateful information of the Generalized Dunn's Index 43 (GD43) CVI.
"""
mutable struct GD43 <: AbstractCVI
    dim::Integer
    n_samples::Integer
    mu_data::RealVector     # dim
    n::IntegerVector        # dim
    v::RealMatrix           # dim x n_clusters
    CP::RealVector          # dim
    G::RealMatrix           # dim x n_clusters
    D::RealMatrix           # n_clusters x n_clusters
    inter::RealFP
    intra::RealFP
    n_clusters::Integer
    criterion_value::RealFP
end # GD43 <: AbstractCVI

"""
    GD43()

Default constructor for the Generalized Dunn's Index 43 (GD43) Cluster Validity Index.
"""
function GD43()
    GD43(
        0,                              # dim
        0,                              # n_samples
        Array{RealFP, 1}(undef, 0),     # mu_data
        Array{Integer, 1}(undef, 0),    # n
        Array{RealFP, 2}(undef, 0, 0),  # v
        Array{RealFP, 1}(undef, 0),     # CP
        Array{RealFP, 2}(undef, 0, 0),  # G
        Array{RealFP, 2}(undef, 0, 0),  # D
        0.0,                            # inter
        0.0,                            # intra
        0,                              # n_clusters
        0.0                             # criterion_value
    )
end # GD43()

"""
    setup!(cvi::GD43, sample::Vector{T}) where {T<:RealFP}
"""
function setup!(cvi::GD43, sample::Vector{T}) where {T<:RealFP}
    # Get the feature dimension
    cvi.dim = length(sample)
    # Initialize the augmenting 2-D arrays with the correct feature dimension
    # NOTE: R is emptied and calculated in evaluate!, so it is not defined here
    cvi.v = Array{T, 2}(undef, cvi.dim, 0)
    cvi.G = Array{T, 2}(undef, cvi.dim, 0)
end # setup!(cvi::GD43, sample::Vector{T}) where {T<:RealFP}

"""
    param_inc!(cvi::GD43, sample::RealVector, label::Integer)

Compute the Generalized Dunn's Index 43 (GD43) CVI incrementally.
"""
function param_inc!(cvi::GD43, sample::RealVector, label::Integer)
    n_samples_new = cvi.n_samples + 1
    if isempty(cvi.mu_data)
        mu_data_new = sample
        setup!(cvi, sample)
    else
        mu_data_new = (1 - 1/n_samples_new) .* cvi.mu_data + (1/n_samples_new) .* sample
    end

    if label > cvi.n_clusters
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
                d_column_new[jx] = sqrt(sum((v_new - cvi.v[:, jx]).^2))
            end
            D_new[:, label] = d_column_new
            D_new[label, :] = transpose(d_column_new)
        end
        # Update 1-D parameters with a push
        cvi.n_clusters += 1
        push!(cvi.CP, CP_new)
        push!(cvi.n, n_new)
        # Update 2-D parameters with appending and reassignment
        cvi.v = [cvi.v v_new]
        cvi.G = [cvi.G G_new]
        cvi.D = D_new
    else
        n_new = cvi.n[label] + 1
        v_new = (1 - 1/n_new) .* cvi.v[:, label] + (1/n_new) .* sample
        delta_v = cvi.v[:, label] - v_new
        diff_x_v = sample .- v_new
        CP_new = cvi.CP[label] + transpose(diff_x_v)*diff_x_v + cvi.n[label]*transpose(delta_v)*delta_v + 2*transpose(delta_v)*cvi.G[:, label]
        G_new = cvi.G[:, label] + diff_x_v + cvi.n[label].*delta_v
        d_column_new = zeros(cvi.n_clusters)
        for jx = 1:cvi.n_clusters
            # Skip the current label index
            if jx == label
                continue
            end
            d_column_new[jx] = sqrt(sum((v_new - cvi.v[:, jx]).^2))
        end
        # Update parameters
        cvi.n[label] = n_new
        cvi.v[:, label] = v_new
        cvi.CP[label] = CP_new
        cvi.G[:, label] = G_new
        cvi.D[:, label] = d_column_new
        cvi.D[label, :] = transpose(d_column_new)
    end
    cvi.n_samples = n_samples_new
    cvi.mu_data = mu_data_new
end # param_inc!(cvi::GD43, sample::RealVector, label::Integer)

"""
    param_batch!(cvi::GD43, data::RealMatrix, labels::IntegerVector)

Compute the Generalized Dunn's Index 43 (GD43) CVI in batch.
"""
function param_batch!(cvi::GD43, data::RealMatrix, labels::IntegerVector)
    cvi.dim, cvi.n_samples = size(data)
    # Take the average across all samples, but cast to 1-D vector
    cvi.mu_data = mean(data, dims=2)[:]
    # u = findfirst.(isequal.(unique(labels)), [labels])
    u = unique(labels)
    cvi.n_clusters = length(u)
    cvi.n = zeros(Integer, cvi.n_clusters)
    cvi.v = zeros(cvi.dim, cvi.n_clusters)
    cvi.CP = zeros(cvi.n_clusters)
    cvi.D = zeros(cvi.n_clusters, cvi.n_clusters)
    for ix = 1:cvi.n_clusters
        subset = data[:, findall(x->x==u[ix], labels)]
        cvi.n[ix] = size(subset, 2)
        cvi.v[1:cvi.dim, ix] = mean(subset, dims=2)
        diff_x_v = subset - cvi.v[:, ix] * ones(1, cvi.n[ix])
        cvi.CP[ix] = sum(diff_x_v.^2)
    end
    for ix = 1 : (cvi.n_clusters - 1)
        for jx = ix + 1 : cvi.n_clusters
            cvi.D[jx, ix] = sqrt(sum((cvi.v[:, ix] - cvi.v[:, jx]).^2))
        end
    end
    cvi.D = cvi.D + transpose(cvi.D)
end # param_batch!(cvi::GD43, data::RealMatrix, labels::IntegerVector)

"""
    evaluate!(cvi::GD43)

Compute the criterion value of the Generalized Dunn's Index 43 (GD43) CVI.
"""
function evaluate!(cvi::GD43)
    cvi.intra = 2*maximum(cvi.CP ./ cvi.n)
    if cvi.n_clusters > 1
        # Between-group measure of separation/isolation
        cvi.inter = minimum(cvi.D[triu(ones(Bool, cvi.n_clusters, cvi.n_clusters), 1)])
        # GD43 index value
        cvi.criterion_value = cvi.inter/cvi.intra
    else
        cvi.criterion_value = 0.0
    end
end # evaluate(cvi::GD43)
