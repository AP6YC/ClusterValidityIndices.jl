using Documenter
using ClusterValidityIndices
using DemoCards

# Generate the demo files
# this is the relative path to docs/
demopage, postprocess_cb, demo_assets = makedemos("examples")

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
        "Tutorial" => [
            "Guide" => "man/guide.md",
            "Examples" => "man/examples.md",
            "Contributing" => "man/contributing.md",
            "Index" => "man/full-index.md"
        ]
    ],
    repo="https://github.com/AP6YC/ClusterValidityIndices.jl/blob/{commit}{path}#L{line}",
    sitename="ClusterValidityIndices.jl",
    authors="Sasha Petrenko",
    # assets=String[],
)

# 3. postprocess after makedocs
postprocess_cb()

deploydocs(
    repo="github.com/AP6YC/ClusterValidityIndices.jl.git",
    devbranch="develop",
)
