# ---
# title: ScikitLearn Comparison
# id: scikit-learn
# cover: assets/scikit-learn.png
# date: 2022-11-11
# author: "[Sasha Petrenko](https://github.com/AP6YC)"
# julia: 1.8
# description: A comparison of CVIs with their equivalent implementations in the scikit-learn Python library.
# ---

# ## Overview

# This demo compares CVIs that are implemented in this package with their equivalents in the scikit-learn Python package.
# We will generate some random distributions, cluster them with different algorithms, and demonstrate that the resulting metrics are equivalent.

# ## Setup

# First, we load our dependencies.

## Load all dependencies
using ClusterValidityIndices    # This package
using Clustering                # k-means
using AdaptiveResonance         # DDVFA
using PyCall                    # scikit-learn interface
using Plots                     # Plots frontend
using Distributions             # Random distribution sampling
using LinearAlgebra             # UniformScaling
gr()                            # Use the default GR backend explicitly
theme(:dracula)                 # Change the theme for fun

# Next, we will set some configuration variables that we will use throughout the script.

## The number of random distributions to sample from
n_distributions = 4
## The number of samples per distribution that we want to draw
n_samples_per = 20
## The number of seed values we will use for k-means
n_k_means = 30
## The dimensionality of the distributions and resulting feature space
dim = 2

# After seeting our variables, we will import the scikit-learn metrics package.
## Use the PyCall interface to import the metrics package
skmetrics = pyimport("sklearn.metrics")

# Next, we will create a series of distributions for random sampling.
## Container for multivariate normal distributions
dists = []
## Iterate over the number of distributions we selected earlier
for i = 1:n_distributions
    ## Set a random vector mean
    mean = 50*rand(dim)
    ## Create a positive definite matrix, guaranteeing dominance of the diagonal
    covariance = rand(Float64, (dim, dim))
    covariance = 0.5 * (covariance' + covariance) + UniformScaling(1)
    ## Add a new distribution to the list
    push!(dists, MvNormal(mean, covariance))
end

# We then create a batch of samples from these distributions.
# While we are here, we can visualize the resulting sample space.
X = reduce(hcat, [rand(dists[i], n_samples_per) for i=1:n_distributions])
p = plot()
scatter!(p, X[1, :], X[2, :])

# ## Cluster and Compute Metrics

# Now, we are ready to do some clustering.
# One use of CVIs is for checking the performance of a clustering algorithm while tweaking its hyperparameters.
# For example, the k-means clustering algorithm is a partition/globular clustering algorithm that requires a seed number as a hyperparameter.
# The "best" seed number for a particular clustering problem varies and is usually unknown, and higher values are more computationally expensive.

# Here, we will cluster the k-means while testing a range of seed values, comparing the equivalence of the Calinski-Harabasz (CH) metric between this package and the scikit-learn implementation.
## Create a range of k-mean seeds to test across along with CVI containers
km_range = 2:n_k_means
criterion_values_jl = zeros(length(km_range))
criterion_values_py = zeros(length(km_range))
for (i, n_clust) = enumerate(km_range)
    ## Get the labels prescribed k-means to each sample
    labels_km = kmeans(X, n_clust).assignments

    ## Create a Calinski-Harabasz CVI and get its criterion value
    cvi = CH()
    criterion_values_jl[i] = get_cvi!(cvi, X, labels_km)

    ## Compute the criterion value with the scikit-learn implementation
    criterion_values_py[i] = skmetrics.calinski_harabasz_score(X', labels_km)
end
## Show that the values are all equivalent between implementations
isapprox(criterion_values_jl, criterion_values_py)

# We can visualize the result as well by plotting the trendlines of the criterion values from each implementation.
q = plot(legend=:bottomright)
plot!(q, km_range, criterion_values_jl, marker=:d)
plot!(q, km_range, criterion_values_py, marker=:d)
ylabel!(q, "Calinski-Harabasz CVI")
xlabel!(q, "K-Means Seed")

# After visualizing the results and seeing that the trendlines are equivalent, we also see that unsurprisingly the best k-means seed value is k=4, since we know that
png("assets/scikit-learn") #hide