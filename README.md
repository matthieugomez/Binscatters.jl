[![Build status](https://github.com/matthieugomez/Binscatters.jl/workflows/CI/badge.svg)](https://github.com/matthieugomez/Binscatters.jl/actions)

This package defines a [`Plots`](https://github.com/JuliaPlots/Plots.jl) recipe to implement the Stata command [`binscatter`](https://github.com/michaelstepner/binscatter) in Julia.

## Syntax

```julia
binscatter(df::Union{DataFrame, GroupedDataFrame}, f::FormulaTerm, n = 20; 
           weights::Union{Symbol, Nothing} = nothing, seriestype::Symbol = :scatter, kwargs...)
```

### Arguments
* `df`: A DataFrame or a GroupedDataFrame
* `f`: A formula created using [`@formula`](@ref). The variable(s) in the left-hand side are plotted on the y-axis. The first variable in the right-hand side is plotted on the x-axis. Add other variables for controls.
* `n`: Number of bins (default to 20).

### Keyword arguments
* `weights`: A symbol for weights
* `seriestype`:
	- `:scatter` (default) only plots bins
	- `:linearfit` plots bins with a regression line
	- `:scatterpath` plots bins with a connecting line
* `kwargs...`: Additional attributes from [`Plots`](http://docs.juliaplots.org/latest/). 


## Examples
```julia
using DataFrames, RDatasets, Plots, Binscatters
df = dataset("datasets", "iris")
```



#### Grouping
Use `binscatter` on a `GroupedDataFrame` to do the plot per group
```julia
gdf = groupby(df, :Species)
binscatter(gdf, @formula(SepalLength ~ SepalWidth), seriestype = :linearfit)
```

#### Options
You can use the typical options in [`Plot`](http://docs.juliaplots.org/latest/) to customize the plot:
```julia
binscatter(df, @formula(SepalLength ~ SepalWidth), seriestype = :scatterpath, linecolor = :blue, markercolor = :blue)
```


#### Residualizing
Length seems to be a decreasing function of with in the `iris` dataset
```julia
binscatter(df, @formula(SepalLength ~ SepalWidth), seriestype = :linearfit)
```
![binscatter](http://www.matthieugomez.com/files/p1.png)

However, it is an increasing function within species
```julia
binscatter(groupby(df, :Species), @formula(SepalLength ~ SepalWidth), seriestype = :linearfit)
```
![binscatter](http://www.matthieugomez.com/files/p2.png)
When there is a large number of groups, a better way to visualize this fact is to partial out the variables with respect to species:
```julia
binscatter(df, @formula(SepalLength ~ SepalWidth + fe(Species)), seriestype = :linearfit)
```
![binscatter](http://www.matthieugomez.com/files/p3.png)


See more examples by typing `?binscatter` in the REPL.

## Installation
The package is registered in the [`General`](https://github.com/JuliaRegistries/General) registry and so can be installed at the REPL with `] add Binscatter`.

