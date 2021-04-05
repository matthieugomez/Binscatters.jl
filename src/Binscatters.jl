module Binscatters
using Statistics
using CategoricalArrays
using DataFrames
using FixedEffectModels
using RecipesBase

include("utils.jl")
"""
    binscatter(df::Union{DataFrame, GroupedDataFrame}, f::FormulaTerm, n::Integer = 20; 
                weights::Union{Symbol, Nothing} = nothing, seriestype::Symbol = :scatter,
                kwargs...)

Outputs a binned scatterplot

### Arguments
* `df`: A Table, a DataFrame or a GroupedDataFrame
* `f`: A formula created using [`@formula`](@ref). The variable(s) in the left-hand side are plotted on the y-axis. The first variable in the right-hand side is plotted on the x-axis. Add other variables for controls.
* `n`: Number of bins (default to 20).

### Keyword arguments
* `weights`: A symbol for weights
* `seriestype`:  `:scatter` (the default) plots bins, `:scatterpath` adds a line to connect the bins, `:linearfit` adds a regression line. 
* `kwargs...`: Additional attributes for [`plot`](@ref). 


### Examples
```julia
using DataFrames, Binscatters, RDatasets, Plots
df = dataset("plm", "Cigar")
binscatter(df, @formula(Sales ~ Price))

# Change the number of bins
binscatter(df, @formula(Sales ~ Price), 10)

# Residualize w.r.t. controls
binscatter(df, @formula(Sales ~ Price + NDI))
binscatter(df, @formula(Sales ~ Price + fe(Year)))

# Plot multiple variables on the y-axis
binscatter(df, @formula(Sales + NDI ~ Price))

# Plot binscatters within groups
df.Post70 = df.Year .>= 70
binscatter(groupby(df, :Post70), @formula(Sales ~ Price))
```
"""
binscatter

mutable struct Binscatter
    args
end
binscatter(args...; kwargs...) = RecipesBase.plot(Binscatter(args); kwargs...)
binscatter!(args...; kwargs...) = RecipesBase.plot!(Binscatter(args); kwargs...)

# User recipe
@recipe function f(bs::Binscatter; weights = nothing)
    df = bin(bs.args...; weights = weights)
    if df isa DataFrame
        cols = names(df)
        N = length(cols)
        x = df[!, end]
        Y = Matrix(df[!, 1:(end-1)])
        @series begin
            seriestype --> :scatter
            markerstrokealpha --> 0.0
            xguide --> cols[end]
            if size(Y, 2) == 1
                yguide --> cols[1]
                label --> ""
            else
                label --> reshape(cols[1:(end-1)], 1, N-1)
            end
            x, Y
        end
    elseif df isa GroupedDataFrame
        for (k, out) in pairs(df)
            cols = string.(valuecols(df))
            N = length(cols)
            x = out[!, end]
            Y = Matrix(out[!, (end-(N-1)):(end-1)])
            str = "(" * join((string(k) * " = " * string(v) for (k, v) in pairs(NamedTuple(k))), ", ") * ")"
            @series begin
                seriestype --> :scatter
                markerstrokealpha --> 0.0
                xguide --> cols[end]
                if size(Y, 2) == 1
                    yguide --> cols[1]
                    label --> str
                else
                    label --> reshape(cols[1:(end-1)], 1, N-1) .* " " .* str
                end
                x, Y
            end
        end
    end
end

function bin(df::AbstractDataFrame, @nospecialize(f::FormulaTerm), n::Integer = 20; 
            weights::Union{Symbol, Nothing} = nothing)
    df = partial_out(df, _shift(f); weights = weights, align = false, add_mean = true)[1]
    cols = names(df)
    df.__cut = cut(df[!, end], n; allowempty = true)
    df = groupby(df, :__cut)
    combine(df, cols .=> mean .=> cols; keepkeys = false)
end

function bin(df::GroupedDataFrame, @nospecialize(f::FormulaTerm), n::Integer = 20; 
            weights::Union{Symbol, Nothing} = nothing)
    combine(d -> bin(d, f, n; weights = weights), df; ungroup = false)
end

function bin(df, @nospecialize(f::FormulaTerm), n::Integer = 20; 
            weights::Union{Symbol, Nothing} = nothing)
    bin(DataFrame(df), f, n; weights = weights)
end
export @formula, fe, binscatter, binscatter!

end
