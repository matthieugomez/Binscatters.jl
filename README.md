This package implements the Stata command [`binscatter`](https://github.com/michaelstepner/binscatter) in Julia. 

## Installation
The package is registered in the [`General`](https://github.com/JuliaRegistries/General) registry and so can be installed at the REPL with `] add Binscatters`.

## Syntax
`binscatter` is implemented as recipe for [`Plots`](https://github.com/JuliaPlots/Plots.jl). Therefore, it is available on any backend.

```julia
using DataFrames, RDatasets, Binscatters, Plots
df = dataset("plm", "Cigar")
binscatter(df, @formula(Sales ~ Price))
```

- Use the usual `Plots` option to change labels colors, etc..
- Residualize with respect to additional controls and high dimensional fixed effects by changing the formula:
```julia
dependent y ~ x +  controls +  fe(fixedeffect)
```
- Binscatter within groups by passing a `GroupedDataFrame` as a first argument.

