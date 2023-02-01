```@meta
DocTestSetup = quote
    using ClusterValidityIndices, Dates
end
```

![header](assets/header.png)

---

These pages serve as the official documentation for the `ClusterValidityIndices.jl` Julia package.

Cluster Validity Indices (CVI) tackle the problem of judging the performance of an unsupervised/clustering algorithm without the availability of truth or supervisory labels, resulting in metrics of under- or over-partitioning.
Furthermore, Incremental CVIs (ICVI) are variants of these ordinarily batch algorithms that enable an online and computationally tractable method of evaluating the performance of a clustering algorithm as it clusters while being numerically equivalent to their batch counterparts.

The purpose of this package is to provide a home for the development and use of these CVIs and ICVIs.
For a list of all CVIs available from the package, see the [Implemented CVI List](@ref cvi-list-page) page.

See the [Index](@ref main-index) for the complete list of documented functions and types.

## Manual Outline

This documentation is split into the following sections:

```@contents
Pages = [
    "getting-started/what-are-cvis.md",
    "getting-started/basic-example.md",
    "man/guide.md",
    "man/cvi-list.md",
    "../examples/index.md",
    "man/contributing.md",
    "man/full-index.md",
    "man/dev-index.md",
]
Depth = 1
```

The [Background](@ref) provides an overview of the problem statement of CVIs and what they are theoretically, while [Basic Example](@ref) steps through an single example workflow.

The [Package Guide](@ref) provides a tutorial to the full usage of the package, while [Examples](@ref examples) gives many sample workflows using a variety of CVI modules.
All CVIs in the package are listed in the [Implemented CVI List](@ref cvi-list-page) page.

Instructions on how to contribute to the package are found in [Contributing](@ref), and docstrings for every element of the package is listed in the [Index](@ref main-index).
Names internal to the package are also listed under the [Developer Index](@ref dev-main-index).


## Documentation Build

This documentation was built using [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl) with the following version and OS:

```@example
using AdaptiveResonance, Dates # hide
println("AdaptiveResonance v$(ADAPTIVERESONANCE_VERSION) docs built $(Dates.now()) with Julia $(VERSION) on $(Sys.KERNEL)") # hide
```

## Citation

If you make use of this project, please generate your citation with the [CITATION.cff](../../CITATION.cff) file of the repository.
Alternatively, you may use the following BibTeX entry for the JOSS paper associated with the repository:

```bibtex
@article{Petrenko2022,
  doi = {10.21105/joss.03527},
  url = {https://doi.org/10.21105/joss.03527},
  year = {2022},
  publisher = {The Open Journal},
  volume = {7},
  number = {79},
  pages = {3527},
  author = {Sasha Petrenko and Donald C. Wunsch},
  title = {ClusterValidityIndices.jl: Batch and Incremental Metrics for Unsupervised Learning},
  journal = {Journal of Open Source Software}
}
```
