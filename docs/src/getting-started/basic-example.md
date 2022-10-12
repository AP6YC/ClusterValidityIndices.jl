# Basic Example

This page gives a basic overview of a workflow using CVIs.
For more detailed and interactive examples that you can run on your own in Julia notebooks, see the [Examples](@ref examples) section.

## CVI Full Usage Example

Consider that you already have a dataset that is labeled by some clustering algorithm.
This is not strictly necessary in practice, as the incremental variants of each CVI are designed to be able to run online alongside a clustering process, but we do so here for simplicity.
We treat the labels here as clustering-prescribed labels rather than true supervised labels, and we treat the data as the samples that were used to cluster to those labels.

We begin by loading the module and creating some made up clustering data:

```julia
# Load the CVI/ICVI module
using ClusterValidityIndices

# Generate some random data as an example
# Here, we have 10 samples with feature dimenison 3
dim = 3
n_samples = 10
data = rand(dim, n_samples)
labels = collect(1:n_samples)
```

Because Julia is column-major in memory, we follow the Julia notation and treat the dimensions of `data` as `[dim, n_samples]`.

We are now ready to instantiate our CVI with default parameters.
Because we have incremental and batch variants, we will instantiate two CVI models, train one sequentially and one in batch, and show that their results are equivalent.
We will use the Davies-Bouldin CVI/ICVI as an example here, but all CVIs in this package have the same usage.

```julia
# Create two containers for the batch and incremental CVIs
cvi_i = DB()
cvi_b = DB()
```

We will preallocate an array for the criterion values of the incremental variant so that we can populate it iteratively.

```julia
# Create some storage for our criterion values
criterion_values_i = zeros(n_samples)
```

We are now ready to evaluate the ICVI incrementally, which we can to in one of two ways.
Most simply, we can use the `get_cvi!` function to evaluate the ICVI and return the criterion value all at once.

```julia
# Iterate across all samples
for ix = 1:n_samples
    # Update the CVI parameters and extract the criterion value in one function
    criterion_values_i[ix] = get_icvi!(cvi_i, data[:, ix], labels[ix])
end
```

If we wish to do all of this in batch, we use the same `get_cvi!` function but pass it a 2-D batch of data and vector of corresponding integer labels:

```julia
# Update and extract the criterion value all at once
criterion_value_b = get_cvi!(cvi_b, data, labels)
```

## [Advance Usage](@id example-advanced-usage)

If you desire more granularity, you can separately update the internal parameters of the CVI, evaluate those internal parameters into a criterion value, and extract that criterion value from the CVI.
For details, see the [Advanced Usage](@ref guide-advanced-usage) section.

For example:

```julia
# Iterate across all of the samples
criterion_values_i = zeros(n_samples)
for ix = 1:n_samples
    # Update the CVI internal parameters incrementally
    param_inc!(cvi_i, data[:, ix], labels[ix])
    # Evaluate the CVI to internally store the criterion value
    evaluate!(cvi_i)
    # Extract and save the criterion value at each step
    criterion_values_i[ix] = cvi_i.criterion_value
end
```

In batch mode, this would also be:

```julia
# Compute the parameters in batch
param_batch!(cvi_b, data, labels)

# Evaluate the CVI criterion value
evaluate!(cvi_b)

# Extract the criterion value
criterion_value_b = cvi_b.criterion_value
```
