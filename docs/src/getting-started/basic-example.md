# Basic Example

This page gives a basic overview of a workflow using CVIs.
For more detailed and interactive examples that you can run on your own in Julia notebooks, see the [Examples](@ref examples) section.

## CVI Full Usage Example

Consider that you already have a dataset that is labeled by some clustering algorithm.
This is not strictly necessary in practice, as the incremental variants of each CVI are designed to be able to run online alongside a clustering process, but we do so here for simplicity.
We treat the labels here as clustering-prescribed labels rather than true supervised labels, and we treat the data as the samples that were used to cluster to those labels.

We begin by loading the module and loading the data wherever it may be:

```julia
# Load the CVI/ICVI module
using ClusterValidityIndices

# Point to the data file
data_path = "data/correct_partition.csv"

# Load the data and labels
data, labels = get_cvi_data(data_path)
```

Because Julia is column-major in memory and our data samples are potentially large, we follow the Julia notation and treat the dimensions of ```data``` as ```[dim, n_samples]```.

!!! note "Note"
    Before ClusterValidityIndices.jl v0.3.0, all the CVIs assume that the labels are presented sequentially initially, starting with index 1 (e.g., 1, 1, 2, 2, 3, 2, 2, 1, 3, 4, 4 ...).
    You may repeat previously seen label indices, but skipping label indices (e.g., 1, 2, 4) results in undefined behavior.
    If your data does not accomodate this, we may circumvent this by relabelling the data monotonically with

    ```julia
    labels = relabel_cvi_data(labels)
    ```

We can get the number of samples from the length of the labels vector because each data sample corresponds to a label:

```julia
# Get the number of samples for incremental iteration
n_samples = length(labels)
```

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

We are now ready to evaluate the ICV incrementally, which we can to in one of two ways.
Most simply, we can use ```get_icvi!``` function to evaluate the ICVI and return the criterion value all at once.

```julia
# Iterate across all samples
for ix = 1:n_samples
    # Update the CVI parameters and extract the criterion value in one function
    criterion_values_i[ix] = get_icvi!(cvi_i, data[:, ix], labels[ix])
end
```

If you desire more granularity, you can separately update the internal parameters of the CVI, evaluate those internal parameters into a criterion value, and extract that criterion value from the CVI.

```julia
# Iterate across all of the samples
for ix = ProgressBar(1:n_samples)
    # Update the CVI internal parameters incrementally
    param_inc!(cvi_i, data[:, ix], labels[ix])
    # Evaluate the CVI to internally store the criterion value
    evaluate!(cvi_i)
    # Extract and save the criterion value at each step
    criterion_values_i[ix] = cvi_i.criterion_value
end
```

If we wish to do all of this in batch, we have methods that correspond to their incremental counterparts at a high level:

```julia
# Update and extract the criterion value all at once
criterion_value_b = get_cvi!(cvi_b, data, labels)
```

and at a more granular level:

```julia
# Compute the parameters in batch
param_batch!(cvi_b, data, labels)

# Evaluate the CVI criterion value
evaluate!(cvi_b)

# Extract the criterion value
criterion_value = cvi_b.criterion_value
```
