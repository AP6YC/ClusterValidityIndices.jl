# Package Guide

The package guide is broken into the following sections:

- [Installation](@ref guide-installation): instructions for the package.
- [Quickstart](@ref guide-quickstart): a simple rundown of the package usage to get it running.
- [Implemented CVIs](@ref implemented-cvis): a list of all batch and incremental CVIs available in the package.
- [Usage](@ref usage): a deep dive of the package and its detailed usage.

## [Installation](@id guide-installation)

This project is distributed as a [Julia](https://julialang.org/) package and hosted on [JuliaHub][pkgeval-url], Julia's package manager repository.
As such, this package's usage follows the usual Julia package installation procedure, interactively:

```julia-repl
julia> ]
(@v1.8) pkg> add ClusterValidityIndices
```

or programmatically:

```julia-repl
julia> using Pkg
julia> Pkg.add("ClusterValidityIndices")
```

You may also add the package directly from GitHub to get the latest changes between releases:

```julia-repl
julia> ]
(@v1.8) pkg> add https://github.com/AP6YC/ClusterValidityIndices.jl
```

## [Quickstart](@id guide-quickstart)

This section provides a quick overview of how to use the project.
For more detailed code usage, please see the [Usage](@ref usage) section.
For a variety of detailed examples that you can run yourself, please see the [Examples](@ref examples) page.

First, import the package with:

```julia
# Import the package
using ClusterValidityIndices
```

CVI objects are instantiated with empty constructors:

```julia
# Create a Davies-Bouldin (DB) CVI object
my_cvi = DB()
```

All CVIs are implemented with acronyms of their literature names.
A list of all of these are found in the [Implemented CVIs](@ref implemented-cvis) section, and their code details can be found in the [Index](@ref index-types).

Next, get data from a clustering process.
This is a set of samples of features that are clustered and prescribed cluster labels.

> **Note**
>
> The `ClusterValidityIndices.jl` package assumes data to be in the form of Float matrices where columns are samples and rows are features.
> An individual sample is a single vector of features.
> Labels are vectors of integers where each number corresponds to its own cluster.

```julia
# Random data as an example; 10 samples with feature dimenison 3
dim = 3
n_samples = 10
data = rand(dim, n_samples)
labels = collect(1:n_samples)
```

The output of CVIs are called *criterion values*, and they can be computed both incrementally and in batch with `get_cvi`.
Compute in batch by providing a matrix of samples and a vector of labels:

```julia
criterion_value = get_cvi(my_cvi, data, labels)
```

or incrementally with the same function by passing one sample and label at a time:

```julia
# Create a container for the values and iterate
criterion_values = zeros(n_samples)
for i = 1:n_samples
    criterion_values[i] = get_cvi(my_cvi, data[:, i], labels[i])
end
```

> **Note**
>
> Each module has a batch and incremental implementation, but `ClusterValidityIndices.jl` does not yet support switching between batch and incremental modes with the same CVI object.

## [Implemented CVIs](@id implemented-cvis)

The `ClusterValidityIndices.jl` package has the following CVIs implemented:

- **CH**: Calinski-Harabasz
- **cSIL**: Centroid-based Silhouette
- **DB**: Davies-Bouldin
- **GD43**: Generalized Dunn's Index 43
- **GD53**: Generalized Dunn's Index 53
- **PS**: Partition Separation
- **rCIP**: (Renyi's) representative Cross Information Potential
- **WB**: WB-index
- **XB**: Xie-Beni

The exported constant `CVI_MODULES` also contains a list of these CVIs for convenient iteration.

## [Usage](@id usage)

The usage of these CVIs covers the following:

- [Data](@ref guide-data) assumptions of the CVIs.
- [How to instantiate](@ref guide-instantiation) the CVIs.
- [Incremental vs. batch](@ref guide-inc-batch) evaluation.
- [Advanced usage](@ref guide-advanced-usage) for under-the-hood.

### [Data](@id guide-data)

Because Julia is programmed in a column-major fashion, all CVIs make the assumption that the first dimension (columns) contains features, while the second dimension (rows) contains samples.
This is more important for batch operation, as incremental operation accepts 1-D sample of features at each time step by definition.

For example,

```julia
# Load data from somewhere
data = load_data()
# The data shape is dimsion x samples
dim, n_samples = size(data)
```

### [Instantiation](@id guide-instantiation)

The names of each CVI are capital abbreviations of their literature names, often based upon the surname of the principal authors of the papers that introduce the metrics.
Every CVI is a subtype of the abstract type `CVI`, and they are all are instantiated with the empty constructor:

```julia
my_cvi = DB()
```

### [Incremental vs. Batch](@id guide-inc-batch)

The CVIs in this project all contain *incremental* and *batch* implementations.
When evaluated in incremental mode, they are often called ICVIs (incremental cluster validity indices) in the literature.
For simplicity, all `CVI` objects have batch and incremental implementations and are simply referred to as CVIs in the documentation.

Either way, you use `get_cvi!`, and the magic of Julia's multiple dispatch handles which implementation to use.
To update in batch, you must provide a 2D matrix of samples along with a vector of integer labels.
To update incrementally, simply provide a single sample with an integer label.

```julia
# Batch
get_cvi!(cvi::CVI, data::RealMatrix, labels::IntegerVector)
# Incremental
get_cvi!(cvi::CVI, sample::RealVector, label::Integer)
```

In both incremental and batch modes, the parameter update requires:

- The CVI being updated.
- The sample (or array of samples).
- The label(s) that was/were prescribed by the clustering algorithm to the sample(s).

### [Advanced Usage](@id guide-advanced-usage)

The CVIs in this project all contain internal *parameters* that must be updated.
Each update function modifies the CVI, so they use the Julia nomenclature convention of appending an exclamation point to indicate as much.

- `param_inc!`/`param_batch!`: updates the internal parameters of the CVI.
- `evaluate!`: computes the criterion value itself.
- `cvi.criterion_value`: contains the last criterion value after evaluation.

More concretely, they are

```julia
# Incremental updating
param_inc!(cvi::CVI, sample::RealVector, label::Integer)
# Batch updating
param_batch!(cvi::CVI, data::RealMatrix, labels::IntegerVector)
```

After updating their internal parameters, they both compute their most recent criterion values with

```julia
evaluate!(cvi::CVI)
```

For example, we may instantiate and load our data

```julia
cvi = DB()
data = load_data()
labels = get_cluster_labels(data)
dim, n_samples = size(data)
```

then update the parameters incrementally with

```julia
criterion_values = zeros(n_samples)
for ix = 1:n_samples
    param_inc!(cvi, data[:, ix], labels[ix])
    evaluate!(cvi)
    criterion_values[ix] = cvi.criterion_value
end
```

or in batch with

```julia
param_batch!(cvi, data, labels)
evaluate!(cvi)
criterion_value = cvi.criterion_value
```

> **Note**
>
> Though this advanced usage is already done all at once with `get_cvi!`, one possible use of this advanced usage is saving computation.
> For example, one might wish to update the CVI internal parameters incrementally each step with `param_inc!` but save the computation of the criterion value itself until it is required with `evaluate!`.
> In all other instances, it is recommended to utilize the public API with `get_cvi!`.
