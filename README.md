[![Build status](https://github.com/matthieugomez/Binscatters.jl/workflows/CI/badge.svg)](https://github.com/matthieugomez/Binscatters.jl/actions)
[![Coverage Status](http://codecov.io/github/matthieugomez/Binscatters.jl/coverage.svg?branch=main)](http://codecov.io/github/matthieugomez/Binscatters.jl/?branch=main)

This package implements the Stata command [`binscatter`](https://github.com/michaelstepner/binscatter) in Julia. It provides a [`Plots`](https://github.com/JuliaPlots/Plots.jl) recipe for binned scatterplots, as well as a standalone `bin` function for use with any plotting backend (e.g. Makie).

## Installation
```julia
] add Binscatters
```

## Quick start

```julia
using DataFrames, Plots, Binscatters, RDatasets
df = dataset("datasets", "iris")

# Basic binscatter
binscatter(df, @formula(SepalLength ~ SepalWidth))

# With a regression line
binscatter(df, @formula(SepalLength ~ SepalWidth), seriestype = :linearfit)
```
![binscatter](http://www.matthieugomez.com/files/p1.png)

## Residualizing

Sepal length appears to be a decreasing function of sepal width in the `iris` dataset. However, it is an increasing function within species. To show this, apply `binscatter` on a `GroupedDataFrame`:
```julia
binscatter(groupby(df, :Species), @formula(SepalLength ~ SepalWidth), seriestype = :linearfit)
```
![binscatter](http://www.matthieugomez.com/files/p2.png)

When there are many groups, a better approach is to partial out the group fixed effects:
```julia
binscatter(df, @formula(SepalLength ~ SepalWidth + fe(Species)), seriestype = :linearfit)
```
![binscatter](http://www.matthieugomez.com/files/p3.png)

You can also residualize with respect to continuous controls:
```julia
binscatter(df, @formula(SepalLength ~ SepalWidth + PetalLength))
```

## Syntax

### `binscatter` (Plots recipe)

```julia
binscatter(df, f, n = 20; weights = nothing, seriestype = :scatter, kwargs...)
```

#### Arguments
* `df`: A DataFrame, GroupedDataFrame, or any Tables.jl-compatible table
* `f`: A formula created using `@formula`. The left-hand side variable(s) are plotted on the y-axis. The first right-hand side variable is plotted on the x-axis. Additional right-hand side variables are used as controls.
* `n`: Number of bins (default: 20)

#### Keyword arguments
* `weights`: A symbol for the weighting variable
* `seriestype`:
  - `:scatter` (default) plots bin means as points
  - `:scatterpath` connects bin means with a line
  - `:linearfit` adds a regression line through the bin means
* `kwargs...`: Any additional [Plots attributes](http://docs.juliaplots.org/latest/)

### `bin` (standalone function)

Returns a DataFrame of bin means, useful with any plotting backend:
```julia
bin(df, f, n = 20; weights = nothing)
```

Example with Makie:
```julia
using CairoMakie, Binscatters
data = bin(df, @formula(SepalLength ~ SepalWidth + fe(Species)))
scatter(data.SepalWidth, data.SepalLength)
```

## More examples

```julia
# Change the number of bins
binscatter(df, @formula(SepalLength ~ SepalWidth), 10)

# Multiple y-variables
binscatter(df, @formula(SepalLength + PetalLength ~ SepalWidth))

# Weighted binscatter
binscatter(df, @formula(SepalLength ~ SepalWidth), weights = :PetalWidth)

# Apply function transforms
binscatter(df, @formula(log(SepalLength) ~ log(SepalWidth)))

# Customize with Plots attributes
binscatter(df, @formula(SepalLength ~ SepalWidth), seriestype = :scatterpath, linecolor = :blue, markercolor = :red)
```

See `?binscatter` in the REPL for the full docstring.
