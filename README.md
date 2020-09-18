This package implements the Stata command [`binscatter`](https://github.com/michaelstepner/binscatter) in Julia. 

## Installation
The package is registered in the [`General`](https://github.com/JuliaRegistries/General) registry and so can be installed at the REPL with `] add Binscatters`.

## Syntax
`binscatter` is implemented as recipe for [`Plots`](https://github.com/JuliaPlots/Plots.jl). 

```julia
using DataFrames, RDatasets, Binscatters, Plots
df = dataset("plm", "Cigar")
binscatter(df, @formula(Sales ~ Price))
```

- Use a formula to specify one y-variable(s), one x-variable, and, eventually, controls and high-dimensional fixedeffects:
	```julia
	@formula(y ~ x +  controls +  fe(fixedeffect))
	```
- Binscatter within groups by passing a `GroupedDataFrame` as a first argument.
- Use the usual `Plots` attributes to change labels colors, etc..

For more documention, type `?binscatter` in the REPL.