# Load all dependencies
using ClusterValidityIndices    # This package
using Clustering                # k-means
using AdaptiveResonance         # DDVFA
using PyCall                    # scikit-learn interface
using Plots                     # Plots frontend
using Distributions             # Random distribution sampling
using LinearAlgebra             # UniformScaling
gr()                            # Use the default GR backend explicitly
theme(:dracula)                 # Change the theme for fun

# The number of random distributions to sample from
n_distributions = 4
# The number of samples per distribution that we want to draw
n_samples_per = 20
# The number of seed values we will use for k-means
n_k_means = 30
# The dimensionality of the distributions and resulting feature space
dim = 2

# Use the PyCall interface to import the metrics package
skmetrics = pyimport("sklearn.metrics")

# Container for multivariate normal distributions
dists = []
# Iterate over the number of distributions we selected earlier
for i = 1:n_distributions
    # Set a random vector mean
    mean = 50*rand(dim)
    # Create a positive definite matrix, guaranteeing dominance of the diagonal
    covariance = rand(Float64, (dim, dim))
    covariance = 0.5 * (covariance' + covariance) + UniformScaling(1)
    # Add a new distribution to the list
    push!(dists, MvNormal(mean, covariance))
end

X = reduce(hcat, [rand(dists[i], n_samples_per) for i=1:n_distributions])
p = plot()
scatter!(p, X[1, :], X[2, :])

# Create a range of k-mean seeds to test across along with CVI containers
km_range = 2:n_k_means
criterion_values_jl = zeros(length(km_range))
criterion_values_py = zeros(length(km_range))
for (i, n_clust) = enumerate(km_range)
    # Get the labels prescribed k-means to each sample
    labels_km = kmeans(X, n_clust).assignments

    # Create a Calinski-Harabasz CVI and get its criterion value
    cvi = CH()
    criterion_values_jl[i] = get_cvi!(cvi, X, labels_km)

    # Compute the criterion value with the scikit-learn implementation
    criterion_values_py[i] = skmetrics.calinski_harabasz_score(X', labels_km)
end
# Show that the values are all equivalent between implementations
isapprox(criterion_values_jl, criterion_values_py)

q = plot(legend=:bottomright)
plot!(q, km_range, criterion_values_jl, marker=:d, label="Julia")
plot!(q, km_range, criterion_values_py, marker=:d, label="Python")
ylabel!(q, "Calinski-Harabasz CVI")
xlabel!(q, "K-Means Seed")

png("assets/scikit-learn") #hide

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

