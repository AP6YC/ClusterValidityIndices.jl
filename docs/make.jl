using Documenter, CVI

makedocs(
    modules=[CVI],
    format=Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
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
    repo="https://github.com/AP6YC/CVI.jl/blob/{commit}{path}#L{line}",
    sitename="AdaptiveResonance.jl",
    authors="Sasha Petrenko",
    # assets=String[],
)

deploydocs(
    repo="github.com/AP6YC/CVI.jl.git",
)
