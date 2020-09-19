[![Build Status](https://travis-ci.com/matthieugomez/Binscatters.jl.svg?branch=master)](https://travis-ci.com/matthieugomez/Binscatters.jl)


This package defines a [`Plots`](https://github.com/JuliaPlots/Plots.jl) recipe to generate binned scatterplots. This implements the Stata command [`binscatter`](https://github.com/michaelstepner/binscatter) in Julia.


## Installation
The package is registered in the [`General`](https://github.com/JuliaRegistries/General) registry and so can be installed at the REPL with `] add Binscatter`.

## Syntax

For more documention, type `?binscatter` in the REPL.

```julia
    binscatter(df::Union{DataFrame, GroupedDataFrame}, f::FormulaTerm, nbins::Integer; 
                weights::Union{Symbol, Nothing} = nothing, seriestype::Symbol = :scatter,
                kwargs...)
```
Outputs a binned scatterplot

### Arguments
* `df`: a DataFrame or a GroupedDataFrame
* `f`: A formula created using [`@formula`](@ref). The variable(s) in the left-hand side are on the y-axis. The first variable in the right-hand side is on the x-axis. The other variables are controls.
* `nbins`: Number of bins

### Keyword arguments
* `weights`: A symbol for weights
* `seriestype`:  `:scatter` (the default) plots bins. `:linearfit` adds a regression line. `:scatterpath` adds a line to connect the bins.
* `kwargs...`: Additional attributes for [`plot`](@ref). 


## Examples
```julia
using DataFrames, RDatasets, Plots, Binscatters
df = dataset("plm", "Cigar")
binscatter(df, @formula(Sales ~ Price))
```
