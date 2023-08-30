using Documenter
using CycleSolver

makedocs(
    sitename = "CycleSolver",
    format = Documenter.HTML(),
    modules = [CycleSolver]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo = "github.com/vFilipaki/CycleSolver.jl"
)
