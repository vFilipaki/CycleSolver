using Documenter
using CycleSolver

makedocs(
    sitename = "CycleSolver",
    format = Documenter.HTML(),
    modules = [CycleSolver],
    pages = [
        "Home" => "index.md",
        "Examples" => Any[
            "Ideal Simple Rankine Cycle" => "example1.md",
            "Rankine cycle with reheat" => "example2.md",
            "Regenerative Rankine Cycle" => "example3.md",
            "Brayton Cycle" => "example4.md",
            "Refrigeration cycle" => "example5.md",
            "Cascade cooling system" => "example6.md",
        ]
    ]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo = "github.com/vFilipaki/CycleSolver.jl"
)
