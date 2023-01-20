using
    BenchmarkTools,
    ClusterValidityIndices

dim = 5
n_samples = 1000
n_labels = 20

features = randn(dim, n_samples)
labels = rand(1:n_labels, n_samples)

# cvi_1 = CH()
# cvi_2 = ClusterValidityIndices.BaseCVI(dim)

function stress_cvi(cvi, features, labels)
# function stress_cvi()
    # dim = 5
    # n_samples = 1000
    # n_labels = 20
    # # cvi = CH()
    # cvi = ClusterValidityIndices.BaseCVI(dim)

    # features = randn(dim, n_samples)
    # labels = rand(1:n_labels, n_samples)

    # for ix = 1:n_samples
    for ix in eachindex(labels)
        sample = features[:, ix]
        label = labels[ix]
        _ = get_cvi!(cvi, sample, label)
    end
end

cvi_1 = CH()
cvi_2 = ClusterValidityIndices.BaseCVI(dim)
# @benchmark stress_cvi(cvi, f, l, n) setup=(cvi=CH(), f=features, l=labels, n=1)
# @benchmark stress_cvi(cv, f, l) setup=(cv=cvi_1, f=features, l=labels)

# @benchmark stress_cvi(cv, features, labels) setup=(cv=cvi_1)
@benchmark stress_cvi(cv, features, labels) setup=(cv=cvi_2)
