# [Implemented CVI List](@id cvi-list-page)

The `ClusterValidityIndices.jl` package has the following CVIs implemented:

```@meta
CurrentModule=ClusterValidityIndices
```

- **[`CH`](@ref)**: Calinski-Harabasz.
- **[`cSIL`](@ref)**: Centroid-based Silhouette.
- **[`DB`](@ref)**: Davies-Bouldin.
- **[`GD43`](@ref)**: Generalized Dunn's Index 43.
- **[`GD53`](@ref)**: Generalized Dunn's Index 53.
- **[`PS`](@ref)**: Partition Separation.
- **[`rCIP`](@ref)**: (Renyi's) representative Cross Information Potential.
- **[`WB`](@ref)**: WB-index.
- **[`XB`](@ref)**: Xie-Beni.

The exported constant [`CVI_MODULES`](@ref ClusterValidityIndices.CVI_MODULES) also contains a list of these CVIs for convenient iteration.
