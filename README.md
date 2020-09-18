[![Build Status](https://travis-ci.com/matthieugomez/Binscatters.jl.svg?branch=master)](https://travis-ci.com/matthieugomez/Binscatters.jl)


This package defines a [`Plots`](https://github.com/JuliaPlots/Plots.jl) recipe to generate binned scatterplots. This implements the Stata command [`binscatter`](https://github.com/michaelstepner/binscatter) in Julia.


## Installation
The package is registered in the [`General`](https://github.com/JuliaRegistries/General) registry and so can be installed at the REPL with `] add Binscatter`.

## Syntax
```julia
using DataFrames, RDatasets, Plots, Binscatters
df = dataset("plm", "Cigar")
binscatter(df, @formula(Sales ~ Price))
```
For more documention, type `?binscatter` in the REPL.