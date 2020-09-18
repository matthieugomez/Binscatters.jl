[![Build Status](https://travis-ci.com/matthieugomez/Binscatters.jl.svg?branch=master)](https://travis-ci.com/matthieugomez/Binscatters.jl)


This package implements a [`Plots`](https://github.com/JuliaPlots/Plots.jl) recipe to generate binned scatterplots. It implements the Stata command [`binscatter`](https://github.com/michaelstepner/binscatter) in Julia.

## Installation
The package is registered in the [`General`](https://github.com/JuliaRegistries/General) registry and so can be installed at the REPL with `] add Binscatters`.

## Syntax

```julia
using DataFrames, RDatasets, Binscatters, Plots
df = dataset("plm", "Cigar")
binscatter(df, @formula(Sales ~ Price))
```
- The first argument is a `DataFrame` or a `GroupedDataFrame`.
- The second argument is a `FormulaTerm`, of the form
	```julia
	@formula(y ~ x + controls +  fe(fixedeffect))
	```
	See the formula syntax from  [`FixedEffectModels`](https://github.com/FixedEffects/FixedEffectModels.jl).
- The keyword argument `n` corresponds to the number of bins
- The keyword arugment `weights` adds weights
- Additional keyword argument correspond to `Plots` attributes

For more documention, type `?binscatter` in the REPL.