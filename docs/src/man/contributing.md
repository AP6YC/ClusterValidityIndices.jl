# Contributing

This page serves as the contribution guide for the `ClusterValidityIndices.jl` package.
From top to bottom, the ways of contributing are:

- [GitHub Issues:](@ref Issues) how to raise an issue with the project.
- [Julia Development:](@ref Julia-Development) how to download and interact with the package.
- [GitFlow:](@ref GitFlow) how to directly contribute code to the package in an organized way on GitHub.
- [Development Details:](@ref Development-Details) how the internals of the package are currently setup if you would like to directly contribute code.

## Issues

The main point of contact is the [GitHub issues](https://github.com/AP6YC/ClusterValidityIndices.jl/issues) page for the project.
This is the easiest way to contribute to the project, as any issue you find or request you have will be addressed there by the authors of the package.
Depending on the issue, the authors will collaborate with you, and after making changes they will link a [pull request](@ref GitFlow) which addresses your concern or implements your proposed changes.

## Julia Development

As a Julia package, development follows the usual procedure:

1. Clone the project from GitHub
2. Switch to or create the branch that you wish work on (see [GitFlow](@ref)).
3. Start Julia at your development folder.
4. Instantiate the package (i.e., download and install the package dependencies).

For example, you can get the package and startup Julia with

```sh
git clone git@github.com:AP6YC/ClusterValidityIndices.jl.git
julia --project=.
```

!!! note "Note"
    In Julia, you must activate your project in the current REPL to point to the location/scope of installed packages.
    The above immediately activates the project when starting up Julia, but you may also separately startup the julia and activate the package with the interactive
    package manager via the `]` syntax:

    ```julia-repl
    julia> ]
    (@v1.8) pkg> activate .
    (ClusterValidityIndices) pkg>
    ```

You may run the package's unit tests after the above setup in Julia with

```julia-repl
julia> using Pkg
julia> Pkg.instantiate()
julia> Pkg.test()
```

or interactively though the Julia package manager with

```julia-repl
julia> ]
(ClusterValidityIndices) pkg> instantiate
(ClusterValidityIndices) pkg> test
```

## GitFlow

As of verson `0.3.1`, the `ClusterValidityIndices.jl` package follows the [GitFlow](https://nvie.com/posts/a-successful-git-branching-model/) git working model.
The [original post](https://nvie.com/posts/a-successful-git-branching-model/) by Vincent Driessen outlines this methodology quite well, while [Atlassian](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow) has a good tutorial as well.
In summary:

1. Create a feature branch off of the `develop` branch with the name `feature/<my-feature-name>`.
2. Commit your changes and push to this feature branch.
3. When you are satisfied with your changes, initiate a [GitHub pull request](https://github.com/AP6YC/ClusterValidityIndices.jl/pulls) (PR) to merge the feature branch with `develop`.
4. If the unit tests pass, the feature branch will first be merged with develop and then be deleted.
5. Releases will be periodically initiated from the `develop` branch and versioned onto the `master` branch.
6. Immediate bug fixes circumvent this process through a `hotfix` branch off of `master`.

## Development Details

### Documentation

These docs are currently hosted as a static site on the GitHub pages platform.
They are setup to be built and served in a separate branch `gh-pages` from the master/development branch of the project.

### Package Structure

The `ClusterValidityIndices.jl` package has the following file structure:

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
└── README.md               // Doc: the README.
```

All CVIs are implemented in separate files in the `src/CVI/` directory, and they are imported to `src/ClusterValidityIndices.jl` through imports in `src/CVI/CVI.jl`.

### CVI Module Workflow

To write a CVI for this project, it will require the following:

1. A struct subtyped from `CVI` that implements the internal parameters in addition to a `Float` named `criterion_value` and a `LabelMap`.
2. A default constructor that initializes values to zeros and arrays to empties (see existing CVI files such as `DB.jl` for examples).
3. An incremental parameter update method `param_inc!(cvi::NEW_CVI, sample::RealVector, label::Integer)` where `NEW_CVI` is the name of the new CVI.
4. A batch parameter update method `param_batch!(cvi::NEW_CVI, data::RealMatrix, labels::IntegerVector)`.
5. A criterion value evaluation method `evaluate(cvi::NEW_CVI)` that updates the internal criterion value.
6. The top-level functions `get_icvi` and `get_cvi` will work automatically after writing the above definitions!

## Authors

If you simply have suggestions for improvement, Sasha Petrenko (<sap625@mst.edu>) is the current developer and maintainer of the ClusterValidityIndices.jl package, so please feel free to reach out with thoughts and questions.
