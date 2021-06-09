# Package Guide

## Installation

The CVI package can be installed using the Julia package manager.
From the Julia REPL, type ']' to enter the Pkg REPL mode and run

```julia
pkg> add CVI
```

Alternatively, it can be added to your environment in a script with

```julia
using Pkg
Pkg.add("CVI")
```

## Quickstart

This section provides a quick overview of how to use the project.
For more detailed code usage, please see [Usage](##Usage).

This project has several example scripts to demonstrate the functionality of CVIs in the ClusterValidityIndices.jl package.
In `ICVI-Examples/src/examples/`, the scripts `db.jl`, `ps.jl`, and `xb.jl` demonstrate usage of the Davies-Boudin (DB), Partition Separation (PS), and Xie-Beni (XB) metrics, respectively.

!!! note "Note"
    Each of these scripts must be run at the top level of the project to correctly point to the datasets.
    For example, they can be run in the shell with

    ```sh
    julia src/examples/db.jl
    ```

    or in a Julia REPL session with

    ```sh
    include("src/examples/db.jl")
    ```

Three preprocessed datasets are provided under `data/` to demonstrate the correct partitioning, over partitioning, and under partitioning of samples by a clustering algorithm to illustrate how the CVIs behave in each case.
The data consists of 2000 samples of 2-element features with the clustering label appended in the third column.
You can change which dataset is used in each script above.

Lastly, there is a large experiment script `src/examples/combined.jl` that runs every CVI with all three datasets.
The common code for all scripts and tests is contained under `test/utils.jl`, while the experiment subroutines referenced in these scripts are under `src/experiments.jl`, so feel free to modify them to further explore the behavior and usage of these CVIs.

## Usage

The usage of these CVIs requires an understanding of:

- [Data](@ref data) assumptions of the CVIs.
- [How to instantiate](@ref instantiation) the CVIs.
- [Incremental vs. batch](@ref inc-batch) evaluation.
- [Updating](@ref updating) internal CVI parameters.
- [Computing and extracting](@ref criterion-values) the criterion values.
- [Porcelain functions](@ref porcelain) that are available to simplify operation.

### [Data](@id data)

Because Julia is programmed in a column-major fashion, all CVIs make the assumption that the first dimension (columns) contains features, while the second dimension (rows) contains samples.
This is more important for batch operation, as incremental operation accepts 1-D sample of features at each time step by definition.

For example,

```julia
# Load data from somewhere
data = load_data()
# The data shape is dimsion x samples
dim, n_samples = size(data)
```

!!! note "Note"
    As of ClusterValidityIndices.jl v0.1.3, all the CVIs assume that the labels are presented sequentially initially, starting with index 1 (e.g., 1, 1, 2, 2, 3, 2, 2, 1, 3, 4, 4 ...).
    You may repeat previously seen label indices, but skipping label indices (e.g., 1, 2, 4) results in undefined behavior.

In this project, this is ameliorated with the function

```julia
relabel_cvi_data(labels::Array{M, 1}) where {M<:Int}
```

For example,

```julia
data_file = "path/to/data.csv"
data, labels = get_cvi_data(data_file)
labels = relabel_cvi_data(labels)
```

Alternatively, you may pairwise sort the entirety of the data with

```julia
sort_cvi_data(data::Array{N, 2}, labels::Array{M, 1}) where {N<:Real, M<:Int}
```

!!! note "Note"
    `sort_cvi_data` reorders the input data as well, which will lead to different ICVI results than with `relabel_cvi_data`.

### [Instantiation](@id instantiation)

The names of each CVI are capital abbreviations of their literature names, often based upon the surname of the principal authors of the papers that introduce the metrics.
All CVIs are implemented with the default constructor, such as

```julia
cvi = DB()
```

### [Incremental vs. Batch](@id inc-batch)

The CVIs in this project all contain *incremental* and *batch* implementations.
When evaluated in incremental mode, they are often called ICVIs (incremental cluster validity indices).
In documentation, CVI refers to both modalities (as in the literature), but in code, CVI means batch and ICVI means incremental.

The funtions that differ between the two modes are how they are updated

```julia
# Incremental
param_inc!(...)
# Batch
param_batch!(...)
```

and their respective porcelain functions

```julia
# Incremental
get_icvi!(...)
# Batch
get_cvi!(...)
```

They both compute their most recent criterion values with

```julia
evaluate!(...)
```

!!! note "Note"
    Any CVI can switch to be updated incrementally or in batch, as the CVI data structs are update mode agnostic.

### [Updating](@id updating)

The CVIs in this project all contain internal *parameters* that must be updated.
Each update function modifies the CVI, so they use the Julia nomenclature convention of appending an exclamation point to indicate as much.

In both incremental and batch modes, the parameter update requires:

- The CVI being updates
- The sample (or array of samples)
- The label(s) that was/were prescribed by the clustering algorithm to the sample(s)

More concretely, they are

```julia
# Incremental updating
param_inc!(cvi::C, sample::Array{T, 1}, label::I) where {C<:AbstractCVI, T<:Real, I<:Int}
# Batch updating
param_batch!(cvi::C, data::Array{T, 2}, labels::Array{I, 1}) where {C<:AbstractCVI, T<:Real, I<:Int}
```

Every CVI is a subtype of the abstract type `AbstractCVI`.
For example, we may instantiate and load our data

```julia
cvi = DB()
data = load_data()
labels = get_cluster_labels(data)
dim, n_samples = size(data)
```

then update the parameters incrementally with

```julia
# Iterate over all samples
for ix = 1:n_samples
    sample = data[:, ix]
    label = labels[ix]
    param_inc!(cvi, sample, labels)
end
```

or in batch with

```julia
param_batch!(cvi, data, labels)
```

Furthermore, any CVI can alternate between being updated in incremental or batch modes, such as

```julia
# Create a new CVI
cvi_mixed = DB()

# Update on half of the data incrementally
i_split = n_samples/2
for ix = 1:i_split
    param_inc!(cvi, data[:, ix], labels[ix])
end

# Update on the other half all at once
param_batch!(cvi, data[:, (i_split+1):end])
```

### [Criterion Values](@id criterion-values)

The CVI parameters are separate from the criterion values that they produce.
This is partly because in batch mode computing the criterion value is only relevant at the last step, which eliminates unnecessarily computing it at every step.
This is also provide granularity to the user that may only which to extract the criterion value occasionally during incremental mode.

Because the criterion values only depend on the internal CVI parameters, they are computed (and internally stored) with

```julia
evaluate!(cvi::C) where {C<:AbstractCVI}
```

To extract them, you must then simply grab the criterion value from the CVI struct with

```julia
criterion_value = cvi.criterion_value
```

For example, after loading the data

```julia
cvi = DB()
data = load_data()
labels = get_cluster_labels(data)
dim, n_samples = size(data)
```

we may extract and return the criterion value at every step with

```julia
criterion_values = zeros(n_samples)
for ix = 1:n_samples
    param_inc!(cvi, data[:, ix], labels[ix])
    evaluate!(cvi)
    criterion_values[ix] = cvi.criterion_value
end
```

or we may get it at the end in batch mode with

```julia
param_batch!(cvi, data, labels)
evaluate!(cvi)
criterion_value = cvi.criterion_value
```

### [Porcelain](@id porcelain)

Taken from the `git` convention of calling low-level operations *plumbing* and high-level user-land functions *porcelain*, the package comes with a small set of *porcelain* function that do common operations all at once for the user.

For example, you may compute, evalute, and return the criterion value all at once with the functions

```julia
# Incremental
get_icvi!(...)
# Batch
get_cvi!(...)
```

Exactly as in the usage for updating the parameters, the functions take the cvi, sample(s), and clustered label(s) as input:

```julia
# Incremental
get_icvi!(cvi::C, x::Array{N, 1}, y::M) where {C<:AbstractCVI, N<:Real, M<:Int}
# Batch
get_cvi!(cvi::C, x::Array{N, 2}, y::Array{M, 1}) where {C<:AbstractCVI, N<:Real, M<:Int}
```

For example, after loading the data you may get the criterion value at each step with

```julia
criterion_values = zeros(n_samples)
for ix = 1:n_samples
    criterion_values[ix] = get_icvi!(cvi, data[:, ix], labels[ix])
end
```

or you may get the final criterion value in batch mode with

```julia
criterion_value = get_cvi!(cvi, data, labels)
```
