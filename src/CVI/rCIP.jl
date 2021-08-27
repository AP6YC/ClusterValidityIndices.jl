"""
    rCIP.jl

This is a Julia port of a MATLAB implementation of batch and incremental
(Renyi's) representative Cross Information Potential (rCIP) Cluster Validity Index.

Authors:
MATLAB implementation: Leonardo Enzo Brito da Silva
Julia port: Sasha Petrenko <sap625@mst.edu>

REFERENCES
[1] L. E. Brito da Silva, N. M. Melton, and D. C. Wunsch II, "Incremental
Cluster Validity Indices for Hard Partitions: Extensions  and  Comparative
Study," ArXiv  e-prints, Feb 2019, arXiv:1902.06711v1 [cs.LG].
[2] E. Gokcay and J. C. Principe, "A new clustering evaluation function
using Renyi’s information potential," in Proc. Int. Conf. Acoust., Speech,
Signal Process. (ICASSP), vol. 6. Jun. 2000, pp. 3490–3493.
[3] E. Gokcay and J. C. Principe, "Information theoretic clustering," IEEE
Trans. Pattern Anal. Mach. Intell., vol. 24, no. 2, pp. 158–171, Feb. 2002.
[4] D. Araújo, A. D. Neto, and A. Martins, "Representative cross information
potential clustering," Pattern Recognit. Lett., vol. 34, no. 16,
pp. 2181–2191, Dec. 2013.
[5] D. Araújo, A. D. Neto, and A. Martins, "Information-theoretic clustering:
A representative and evolutionary approach," Expert Syst. Appl.,
vol. 40, no. 10, pp. 4190–4205, Aug. 2013.
[6] R. O. Duda, P. E. Hart, and D. G. Stork, Pattern Classification, 2nd ed.
John Wiley & Sons, 2000.
"""

using Statistics
using LinearAlgebra

"""
    rCIP

The stateful information of the (Renyi's) representative Cross Information Potential (rCIP) CVI.
"""
mutable struct rCIP <: AbstractCVI
    dim::Integer
    n_samples::Integer
    n::IntegerVector            # dim
    v::RealMatrix               # dim x n_clusters
    sigma::Array{RealFP, 3}     # dim x dim x n_clusters
    constant::RealFP
    D::RealMatrix               # n_clusters x n_clusters
    delta_term::RealMatrix      # dim x dim
    n_clusters::Integer
    criterion_value::RealFP
end # rCIP <: AbstractCVI

"""
    rCIP()

Default constructor for the (Renyi's) representative Cross Information Potential (rCIP) Cluster Validity Index.
"""
function rCIP()
    rCIP(
        0,                                  # dim
        0,                                  # n_samples
        Array{Integer, 1}(undef, 0),          # n
        Array{RealFP, 2}(undef, 0, 0),     # v
        Array{RealFP, 3}(undef, 0, 0, 0),  # sigma
        0.0,                                # constant
        Array{RealFP, 2}(undef, 0, 0),     # D
        Array{RealFP, 2}(undef, 0, 0),     # delta_term
        0,                                  # n_clusters
        0.0                                 # criterion_value
    )
end # rCIP()

"""
    setup!(cvi::rCIP, sample::Vector{T}) where {T<:RealFP}
"""
function setup!(cvi::rCIP, sample::Vector{T}) where {T<:RealFP}
    # Get the feature dimension
    cvi.dim = length(sample)
    # Initialize the 2-D and 3-D arrays with the correct feature dimension
    cvi.v = Array{T, 2}(undef, cvi.dim, 0)
    cvi.sigma = Array{T, 3}(undef, cvi.dim, cvi.dim, 0)
    # Calculate the delta term
    epsilon = 12
    delta = 10^(-epsilon/cvi.dim)
    cvi.delta_term = Matrix{Float64}(LinearAlgebra.I, cvi.dim, cvi.dim).*delta
end # setup!(cvi::rCIP, sample::Vector{T}) where {T<:RealFP}

"""
    param_inc!(cvi::rCIP, sample::RealVector, label::Integer)

Compute the (Renyi's) representative Cross Information Potential (rCIP) CVI incrementally.
"""
function param_inc!(cvi::rCIP, sample::RealVector, label::Integer)
    n_samples_new = cvi.n_samples + 1
    if isempty(cvi.v)
        setup!(cvi, sample)
    end
    cvi.constant = 1/sqrt((2*pi)^cvi.dim)

    if label > cvi.n_clusters
        n_new = 1
        v_new = sample
        sigma_new = cvi.delta_term
        if cvi.n_clusters == 0
            D_new = zeros(1, 1)
        else
            D_new = zeros(cvi.n_clusters + 1, cvi.n_clusters + 1)
            D_new[1:cvi.n_clusters, 1:cvi.n_clusters] = cvi.D
            d_column_new = zeros(cvi.n_clusters + 1)
            for jx = 1:cvi.n_clusters
                diff_m = v_new - cvi.v[:, jx]
                sigma_q = sigma_new + cvi.sigma[:,:,jx]
                d_column_new[jx] = cvi.constant * (1/sqrt(det(sigma_q)))*exp(-0.5*transpose(diff_m)*inv(sigma_q)*diff_m)
                # d_column_new[jx] = sum((v_new - cvi.v[:, jx]).^2)
            end
            D_new[:, label] = d_column_new
            D_new[label, :] = transpose(d_column_new)
        end
        # Update 1-D parameters with a push
        cvi.n_clusters += 1
        push!(cvi.n, n_new)
        # Update 2-D parameters with appending and reassignment
        cvi.v = [cvi.v v_new]
        cvi.D = D_new
        cvi.sigma = cat(cvi.sigma, sigma_new, dims=3)
    else
        n_new = cvi.n[label] + 1
        v_new = (1 - 1/n_new) .* cvi.v[:, label] + (1/n_new) .* sample
        diff_x_v = sample - cvi.v[:, label]
        if n_new > 1
            sigma_new = ((n_new - 2)/(n_new - 1))*(cvi.sigma[:,:,label] - cvi.delta_term) +
                (1/n_new)*(diff_x_v*transpose(diff_x_v)) + cvi.delta_term
        else
            sigma_new = cvi.delta_term
        end
        d_column_new = zeros(cvi.n_clusters)
        for jx = 1:cvi.n_clusters
            if jx == label
                continue
            end
            diff_m = v_new - cvi.v[:, jx]
            sigma_q = sigma_new + cvi.sigma[:,:,jx]
            d_column_new[jx] = cvi.constant*(1/sqrt(det(sigma_q)))*exp(-0.5*transpose(diff_m)*inv(sigma_q)*diff_m)
        end
        # Update parameters
        cvi.n[label] = n_new
        cvi.v[:, label] = v_new
        cvi.sigma[:,:,label] = sigma_new
        cvi.D[:, label] = d_column_new
        cvi.D[label, :] = transpose(d_column_new)
    end
    cvi.n_samples = n_samples_new
end # param_inc!(cvi::rCIP, sample::RealVector, label::Integer)

"""
    param_batch!(cvi::rCIP, data::RealMatrix, labels::IntegerVector)

Compute the (Renyi's) representative Cross Information Potential (rCIP) CVI in batch.
"""
function param_batch!(cvi::rCIP, data::RealMatrix, labels::IntegerVector)
    cvi.dim, cvi.n_samples = size(data)
    cvi.constant = 1/sqrt((2*pi)^cvi.dim)
    # Calculate the delta term
    epsilon = 12
    delta = 10^(-epsilon/cvi.dim)
    cvi.delta_term = Matrix{Float64}(LinearAlgebra.I, cvi.dim, cvi.dim).*delta

    # Take the average across all samples, but cast to 1-D vector
    u = unique(labels)
    cvi.n_clusters = length(u)
    cvi.n = zeros(Integer, cvi.n_clusters)
    cvi.v = zeros(cvi.dim, cvi.n_clusters)
    cvi.sigma = zeros(cvi.dim, cvi.dim, cvi.n_clusters)
    cvi.D = zeros(cvi.n_clusters, cvi.n_clusters)

    for ix = 1:cvi.n_clusters
        subset = data[:, findall(x->x==u[ix], labels)]
        cvi.n[ix] = size(subset, 2)
        cvi.v[1:cvi.dim, ix] = mean(subset, dims=2)
        if cvi.n[ix] > 1
            cvi.sigma[:,:,ix] = (1/(cvi.n[ix] - 1)) *
                ((subset*transpose(subset)) - cvi.n[ix].*cvi.v[:,ix]*transpose(cvi.v[:,ix])) +
                cvi.delta_term
        else
            cvi.sigma[:,:,ix] = cvi.delta_term
        end
    end
    for ix = 1 : (cvi.n_clusters - 1)
        for jx = ix + 1 : cvi.n_clusters
            diff_m = cvi.v[:, ix] - cvi.v[:, jx]
            sigma_q = cvi.sigma[:,:,ix] + cvi.sigma[:,:,jx]
            cvi.D[jx, ix] = cvi.constant*(1/sqrt(det(sigma_q)))*exp(-0.5*transpose(diff_m)*inv(sigma_q)*diff_m)
        end
    end
    cvi.D = cvi.D + transpose(cvi.D)
end # param_batch!(cvi::rCIP, data::RealMatrix, labels::IntegerVector)

"""
    evaluate!(cvi::rCIP)

Compute the criterion value of the (Renyi's) representative Cross Information Potential (rCIP) CVI.
"""
function evaluate!(cvi::rCIP)
    # Assume a symmetric dimension
    dim = size(cvi.D)[1]
    if dim > 1
        values = [cvi.D[i,j] for i = 1:dim, j=1:dim if j > i]
        cvi.criterion_value = sum(values)
    else
        cvi.criterion_value = 0.0
    end
end # evaluate(cvi::rCIP)
