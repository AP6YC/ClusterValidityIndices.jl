# ClusterValidityIndices

A Julia package for Cluster Validity Indices (CVI) algorithms.

| **Documentation**  | **Build Status** | **Coverage** |
|:------------------:|:----------------:|:------------:|
| [![Stable][docs-stable-img]][docs-stable-url] | [![Build Status][ci-img]][ci-url] | [![Codecov][codecov-img]][codecov-url] |
| [![Dev][docs-dev-img]][docs-dev-url] | [![Build Status][appveyor-img]][appveyor-url] | [![Coveralls][coveralls-img]][coveralls-url] |
| **Dependents** | **Date** | **Status** |
| [![deps][deps-img]][deps-url] | [![version][version-img]][version-url] | [![pkgeval][pkgeval-img]][pkgeval-url] |

| **Zenodo DOI** |
| :------------: |
| [![DOI][zenodo-img]][zenodo-url] |

[zenodo-img]: https://zenodo.org/badge/DOI/10.5281/zenodo.5765807.svg
[zenodo-url]: https://doi.org/10.5281/zenodo.5765807

[deps-img]: https://juliahub.com/docs/ClusterValidityIndices/deps.svg
[deps-url]: https://juliahub.com/ui/Packages/ClusterValidityIndices/Z19r6?t=2

[version-img]: https://juliahub.com/docs/ClusterValidityIndices/version.svg
[version-url]: https://juliahub.com/ui/Packages/ClusterValidityIndices/Z19r6

[pkgeval-img]: https://juliahub.com/docs/ClusterValidityIndices/pkgeval.svg
[pkgeval-url]: https://juliahub.com/ui/Packages/ClusterValidityIndices/Z19r6

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://AP6YC.github.io/ClusterValidityIndices.jl/stable

[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://AP6YC.github.io/ClusterValidityIndices.jl/dev

[ci-img]: https://github.com/AP6YC/ClusterValidityIndices.jl/workflows/CI/badge.svg
[ci-url]: https://github.com/AP6YC/ClusterValidityIndices.jl/actions?query=workflow%3ACI

[appveyor-img]: https://ci.appveyor.com/api/projects/status/github/AP6YC/ClusterValidityIndices.jl?svg=true
[appveyor-url]: https://ci.appveyor.com/project/AP6YC/ClusterValidityIndices-jl

[codecov-img]: https://codecov.io/gh/AP6YC/ClusterValidityIndices.jl/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/AP6YC/ClusterValidityIndices.jl

[coveralls-img]: https://coveralls.io/repos/github/AP6YC/ClusterValidityIndices.jl/badge.svg?branch=master
[coveralls-url]: https://coveralls.io/github/AP6YC/ClusterValidityIndices.jl?branch=master

[issues-url]: https://github.com/AP6YC/ClusterValidityIndices.jl/issues
[contrib-url]: https://ap6yc.github.io/ClusterValidityIndices.jl/dev/man/contributing/

Please read the [documentation](https://ap6yc.github.io/ClusterValidityIndices.jl/dev/) for detailed usage and tutorials.

## Table of Contents

- [ClusterValidityIndices](#clustervalidityindices)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
    - [Installation](#installation)
    - [Quickstart](#quickstart)
    - [Implemented CVI/ICVIs](#implemented-cviicvis)
    - [Examples](#examples)
  - [Structure](#structure)
  - [Contributing](#contributing)
  - [Acknowledgements](#acknowledgements)
    - [Authors](#authors)
  - [License](#license)

## Overview

Cluster Validity Indices (CVIs) are designed to be metrics of performance for unsupervised clustering algorithms.
In the absense of supervisory labels (i.e., ground truth), clustering algorithms - or any truly unsupervised learning algorithms - have no way to definitively know the stability of their learning and accuracy of their performance.
As a result, CVIs exist to provide metrics of partitioning stability/validity through the use of only the original data samples and the cluster labels prescribed by the clustering algorithm.

This Julia package contains an outline of the conceptual usage of CVIs along with many [example scripts in the documentation](https://ap6yc.github.io/ClusterValidityIndices.jl/dev/examples/).
This outline begins with [a list of CVIs](#implemented-cviicvis) that are implemented in the lastest version of the project.
[Quickstart](#quickstart) provides an overview of how to use this project, while [Structure](#structure) outlines the project file structure, giving context to the locations of every component of the project.
[Usage](#usage) outlines the general syntax and workflow of the CVIs/ICVIs.

### Installation

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

### Quickstart

This section provides a quick overview of how to use the project.
For more detailed code usage, please see the [Detailed Usage](@ref usage).

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
A list of all of these are found in the [Implemented CVIs/ICVIs](#implemented-cviicvis) section.

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

### Implemented CVI/ICVIs

This project has implementations of the following CVIs in both batch and incremental variants:

- **[`CH`][1]**: Calinski-Harabasz
- **[`cSIL`][2]**: Centroid-based Silhouette
- **[`DB`][3]**: Davies-Bouldin
- **[`GD43`][4]**: Generalized Dunn's Index 43
- **[`GD53`][5]**: Generalized Dunn's Index 53
- **[`PS`][6]**: Partition Separation
- **[`rCIP`][7]**: (Renyi's) representative Cross Information Potential
- **[`WB`][8]**: WB-index
- **[`XB`][9]**: Xie-Beni

[1]: https://AP6YC.github.io/ClusterValidityIndices.jl/dev/man/full-index/#ClusterValidityIndices.CH
[2]: https://AP6YC.github.io/ClusterValidityIndices.jl/dev/man/full-index/#ClusterValidityIndices.cSIL
[3]: https://AP6YC.github.io/ClusterValidityIndices.jl/dev/man/full-index/#ClusterValidityIndices.DB
[4]: https://AP6YC.github.io/ClusterValidityIndices.jl/dev/man/full-index/#ClusterValidityIndices.GD43
[5]: https://AP6YC.github.io/ClusterValidityIndices.jl/dev/man/full-index/#ClusterValidityIndices.GD53
[6]: https://AP6YC.github.io/ClusterValidityIndices.jl/dev/man/full-index/#ClusterValidityIndices.PS
[7]: https://AP6YC.github.io/ClusterValidityIndices.jl/dev/man/full-index/#ClusterValidityIndices.rCIP
[8]: https://AP6YC.github.io/ClusterValidityIndices.jl/dev/man/full-index/#ClusterValidityIndices.WB
[9]: https://AP6YC.github.io/ClusterValidityIndices.jl/dev/man/full-index/#ClusterValidityIndices.XB

The exported constant `CVI_MODULES` also contains a list of these CVIs for convenient iteration.

### Examples

A [basic example](https://ap6yc.github.io/ClusterValidityIndices.jl/dev/getting-started/basic-example/) of the package usage is found in the documentation illustrating top-down usage of the package.

Futhermore, there are a variety of examples in the [Examples](https://ap6yc.github.io/ClusterValidityIndices.jl/dev/examples/) section of the documentation for a variety of use cases of the project.
Each of these is made using the [`DemoCards.jl`](https://github.com/johnnychen94/DemoCards.jl) package and can be opened, saved, and run as a Julia notebook.

## Structure

The following reference describes the role of each top-level folder and file in the project:

```console
ClusterValidityIndices.jl
├── .github/workflows       // GitHub: workflows for testing and documentation.
├── data                    // Data: CI and example data location.
├── docs                    // Docs: GitHub pages documentation files.
├── paper                   // Docs: JOSS paper and bib files.
├── src                     // Source: scripts and common helper functions.
│   └─── CVI                //      All CVI and ICVI definitions
├── test                    // Test: unit, integration, and environment tests.
├── .appveyor               // CI: Appveyor CI script
├── .gitignore              // Git: .gitignore for the whole project.
├── CODE_OF_CONDUCT         // Doc: the expectations of contributors to the project.
├── CONTRIBUTING            // Doc: a summary of contribution guidelines, pointing to these docs.
├── LICENSE                 // Doc: the license to the project.
├── Manifest.toml           // Julia: the explicit package versions used (ignored).
├── Project.toml            // Julia: the Pkg.jl dependencies of the project.
└── README.md               // Doc: this document.
```

## Contributing

If you have a question or concern, please raise an [issue][issues-url].
For more details on how to work with the project, propose changes, or even contribute code, please see the [Developer Notes][contrib-url] in the project's documentation.

In summary:

1. Questions and requested changes should all be made in the [issues][issues-url] page.
These are preferred because they are publicly viewable and could assist or educate others with similar issues or questions.
2. For changes, this project accepts pull requests (PRs) from `feature/<my-feature>` branches onto the `develop` branch using the [GitFlow](https://nvie.com/posts/a-successful-git-branching-model/) methodology.
If unit tests pass and the changes are beneficial, these PRs are merged into `develop` and eventually folded into versioned releases.
3. The project follows the [Semantic Versioning](https://semver.org/) convention of `major.minor.patch` incremental versioning numbers.
Patch versions are for bug fixes, minor versions are for backward-compatible changes, and major versions are for new and incompatible usage changes.

## Acknowledgements

### Authors

This package is developed and maintained by [Sasha Petrenko](https://github.com/AP6YC) with sponsorship by the [Applied Computational Intelligence Laboratory (ACIL)](https://acil.mst.edu/).
This project is supported by grants from the [Night Vision Electronic Sensors Directorate](https://c5isr.ccdc.army.mil/inside_c5isr_center/nvesd/), the [DARPA Lifelong Learning Machines (L2M) program](https://www.darpa.mil/program/lifelong-learning-machines), [Teledyne Technologies](http://www.teledyne.com/), and the [National Science Foundation](https://www.nsf.gov/).
The material, findings, and conclusions here do not necessarily reflect the views of these entities.

The users [@rMassimiliano](https://github.com/rMassimiliano) and [@malmaud](https://github.com/malmaud) have graciously contributed their time with reviews and feedback that has greatly improved the project.

## License

This software is openly maintained by the ACIL of the Missouri University of Science and Technology under the [MIT License](LICENSE).
