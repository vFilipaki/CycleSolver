<div align="center">
  <a href="https://github.com/othneildrew/Best-README-Template">
    <img src="https://github.com/vFilipaki/CycleSolver.jl/blob/main/docs/src/assets/logo.png?raw=true" alt="Logo" width="200" height="200">
  </a>

  <h1 align="center">CycleSolver</h1>

  <p align="center">
    <a href="https://github.com/vFilipaki/CycleSolver.jl/actions/workflows/CI.yml?query=branch%3Amaster"><img src="https://github.com/vFilipaki/CycleSolver.jl/actions/workflows/CI.yml/badge.svg?branch=main"></a>
    <a href="https://vfilipaki.github.io/CycleSolver.jl/stable/"><img src="https://img.shields.io/badge/docs-stable-blue.svg"></a>
    <a href="https://codecov.io/gh/vFilipaki/CycleSolver.jl"><img src="https://codecov.io/gh/vFilipaki/CycleSolver.jl/graph/badge.svg?token=XA1IQOY99S)"></a>
    <a href="https://juliahub.com/ui/Packages/General/CycleSolver"><img src="https://juliahub.com/docs/General/CycleSolver/stable/version.svg"></a>
    <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-yellow.svg"></a>
    <br />
    <br />
    Package for solving thermodynamic cycles in steady state 
    <br />
    <a href="https://vfilipaki.github.io/CycleSolver.jl/stable/"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/vFilipaki/CycleSolver.jl#installation">How to install</a>
    ·
    <a href="https://github.com/vFilipaki/CycleSolver.jl#citations">How to cite this project</a>
    ·
    <a href="https://vfilipaki.github.io/CycleSolver.jl/dev/example1/">See examples</a>
</div>

---

The `CycleSolver.jl` package uses metaprogramming to provide a unique formatting structure for representing cycles and supplying already known properties. Based on this, the algorithm seeks to automatically discover other unknown properties of the system.

In addition to cycle solving, the presented package also offers result visualization features, generating tables and graphs to clearly illustrate cycle properties. This way, the tool allows for a quick and reliable analysis of thermodynamic cycles.

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

## Documentation

For information on how to use the package, see the [documentation](https://vfilipaki.github.io/CycleSolver.jl/dev/).

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
