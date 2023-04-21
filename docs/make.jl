using Documenter, CycleSolver

makedocs(modules = [CycleSolver], sitename = "CycleSolver.jl")

deploydocs(repo = "github.com/CycleSolver.jl.git")