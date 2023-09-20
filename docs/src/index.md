# CycleSolver.jl

#### Package for solving thermodynamic cycles in steady state 

> This package uses metaprogramming to provide a unique formatting structure for representing cycles and supplying already known properties. Based on this, the algorithm seeks to automatically discover other unknown properties of the system.
>
> In addition to cycle solving, the presented package also offers result visualization features, generating tables and graphs to clearly illustrate cycle properties. This way, the tool allows for a quick and reliable analysis of thermodynamic cycles.

## Installation
To install `CycleSolver.jl`, use the Julia package manager. In Julia REPL, type `]` to enter Pkg REPL mode and run:

```julia
pkg> add CycleSolver
```
Or, you can install via the Pkg API:
```julia
julia> using Pkg

julia> Pkg.add("CycleSolver")
```

Additionally, you have the option to use the `CycleSolver.jl` package in an online environment, without the need for any local software installation. You can access it through the following link:
 * [CycleSolver Online](https://mybinder.org/v2/gh/vFilipaki/CycleSolver.jl/v0.3.0)
 
## Citations

How to cite this project:

```bibtex
@Misc{2023-FilipakiV-CycleSolver,
  author       = {V. Filipaki},
  title        = {{CycleSolver.jl} -- Solver for thermodynamic cycles},
  howpublished = {Online},
  month        = {August},
  year         = {2023},
  journal      = {GitHub repository},
  publisher    = {GitHub},
  url          = {https://github.com/vFilipaki/CycleSolver.jl},
}
```
