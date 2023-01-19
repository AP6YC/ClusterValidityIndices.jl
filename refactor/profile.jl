using Revise
using ClusterValidityIndices

function profile_test(n_iterations::Integer, n_samples::Integer)
    for ix = 1:n_iterations
        dim = 100
        n_labels = 100
        features = randn(dim, n_samples)
        labels = rand(1:n_labels, n_samples)
        # cvi = CH()
        # cvi = DB()
        cvi = ClusterValidityIndices.BaseCVI(dim)
        for jx = 1:n_samples
            sample = features[:, jx]
            label = labels[jx]
            _ = get_cvi!(cvi, sample, label)
        end
    end
end

# Compilation
@profview profile_test(1, 5)
# Runtime
@profview profile_test(5, 10000)
# @time profile_test(5, 1000)