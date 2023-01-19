# Use Revise first to track other changes
using Revise

# Include dependencies
using
    ClusterValidityIndices,
    Random

# Set the random seed
Random.seed!(1)

dim = 5
n_samples = 1000
n_labels = 20

features = randn(dim, n_samples)
labels = rand(1:n_labels, n_samples)
cvi_1 = CH()
cvi_2 = ClusterValidityIndices.BaseCVI(dim)

p_cvi_1 = zeros(n_samples)
p_cvi_2 = zeros(n_samples)
for ix = 1:n_samples
    sample = features[:, ix]
    label = labels[ix]
    p_cvi_1[ix] = get_cvi!(cvi_1, sample, label)
    p_cvi_2[ix] = get_cvi!(cvi_2, sample, label)

end

for ix = 1:n_samples
    try
        @assert p_cvi_1[ix] === p_cvi_2[ix]
    catch
        @info "Bad at $(ix):" p_cvi_1[ix] p_cvi_2[ix]
    end
end
