"""
    make.jl

This file builds the documentation for the ClusterValidityIndices.jl package
using Documenter.jl and other tools.
"""

# --------------------------------------------------------------------------- #
# DEPENDENCIES
# --------------------------------------------------------------------------- #

using
    Documenter,
    DemoCards,
    Pkg

# --------------------------------------------------------------------------- #
# SETUP
# --------------------------------------------------------------------------- #

# Fix GR headless errors
ENV["GKSwstype"] = "100"

# Get the current workind directory's base name
current_dir = basename(pwd())
@info "Current directory is $(current_dir)"

# If using the CI method `julia --project=docs/ docs/make.jl`
#   or `julia --startup-file=no --project=docs/ docs/make.jl`
if occursin("ClusterValidityIndices", current_dir)
    push!(LOAD_PATH, "../src/")
# Otherwise, we are already in the docs project and need to dev the above package
elseif occursin("docs", current_dir)
    Pkg.develop(path="..")
# Otherwise, building docs from the wrong path
else
    error("Unrecognized docs setup path")
end

# Include the package
using ClusterValidityIndices

# --------------------------------------------------------------------------- #
# GENERATE
# --------------------------------------------------------------------------- #

# Generate the demo files
# this is the relative path to docs/
demopage, postprocess_cb, demo_assets = makedemos("examples")

# Add the favicon to the assets list
assets = [
    joinpath("assets", "favicon.ico")
]

# if there are generated css assets, pass it to Documenter.HTML
isnothing(demo_assets) || (push!(assets, demo_assets))

# Make the documentation
makedocs(
    modules=[ClusterValidityIndices],
    format=Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
        assets = assets,
    ),
    # format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
        "Getting Started" => [
            "getting-started/what-are-cvis.md",
            "getting-started/basic-example.md",
        ],
        "Manual" => [
            "Guide" => "man/guide.md",
            # "Examples" => "man/examples.md",
            demopage,
            "Contributing" => "man/contributing.md",
            "Index" => "man/full-index.md",
            "Internals" => "man/dev-index.md",
        ]
    ],
    repo="https://github.com/AP6YC/ClusterValidityIndices.jl/blob/{commit}{path}#L{line}",
    sitename="ClusterValidityIndices.jl",
    authors="Sasha Petrenko",
    # assets=String[],
)

# Postprocess after makedocs
postprocess_cb()

# --------------------------------------------------------------------------- #
# DEPLOY
# --------------------------------------------------------------------------- #

# Deploy the documentation, pointing to `develop` as the devbranch`
deploydocs(
    repo="github.com/AP6YC/ClusterValidityIndices.jl.git",
    devbranch="develop",
)
