module Binscatters

using DataFrames
using Statistics
using FixedEffectModels
using RecipesBase
using CategoricalArrays

"""
    binscatter(df::Union{DataFrame, GroupedDataFrame}, f::FormulaTerm, ngroups::Integer; 
                weights = nothing, kwargs...)

Generate a binned scatterplot

### Arguments
* `df`: a DataFrame or a GroupedDataFrame
* `f`: A formula created using [`@formula`](@ref). The variable(s) in the left-hand side are on the y-axis. The first variable in the right-hand side is on the x-axis. Use other terms for controls.
* `ngroups`: Number of bins
* `weights`: A symbol for weights
* `kwargs...`: Additional attributes from [`Plots`](@ref)

### Examples
```julia
using DataFrames, Binscatters, RDatasets, Plots
pgfplotsx()
df = dataset("plm", "Cigar")
binscatter(df, @formula(Sales ~ Price))
binscatter(df, @formula(Sales ~ Price), n = 10)
binscatter(df, @formula(Sales ~ Price), n = 10, color = :black)

# Use controls
binscatter(df, @formula(Sales ~ Price + NDI))
binscatter(df, @formula(Sales ~ Price + NDI + fe(Year)))

# Plot multiple variables
binscatter(df, @formula(Sales + NDI ~ Price))

# binscatter by groups
df.Post70 = df.Year .>= 70
binscatter(groupby(df, :Post70), @formula(Sales ~ Price + fe(Year)))
```
"""
binscatter

function bin(df::AbstractDataFrame, @nospecialize(f::FormulaTerm), ngroups::Integer = 20; weights::Union{Symbol, Nothing} = nothing)
    df = partial_out(df, _shift(f); weights = weights, align = false, add_mean = true)[1]
    cols = names(df)
    df.__cut = cut(df[!, end], ngroups; allowempty = true)
    df = groupby(df, :__cut)
    combine(df, cols .=> mean .=> cols; keepkeys = false)
end

function bin(df::GroupedDataFrame, @nospecialize(f::FormulaTerm), ngroups::Integer = 20; weights::Union{Symbol, Nothing} = nothing, n = 20)
    combine(d -> bin(d, f; weights = weights, ngroups = ngroups), df; ungroup = false)
end


function _shift(@nospecialize(formula::FormulaTerm))
    lhs = formula.lhs
    rhs = formula.rhs
    if !(lhs isa Tuple)
        lhs = (lhs,)
    end
    if !(rhs isa Tuple)
        rhs = (rhs,)
    end
    i = findfirst(x -> x isa Term, rhs)
    FormulaTerm(tuple(lhs..., rhs[i]), Tuple(term for term in rhs if term != rhs[i]))
end

#user recipe
mutable struct Binscatter
    args
end
binscatter(args...;kw...) = plot(Binscatter(args); kw....)
binscatter!(args...;kw...) = plot!(Binscatter(args); kw....)
@recipe function f(bs::BinScatter; weights = nothing)
    df = bin(bs.args...; weights = weights)
    if df isa DataFrame
        cols = names(df)
        N = length(cols)
        seriestype --> :scatter
        xguide := cols[end]
        label := reshape(cols[1:(end-1)], 1, N-1)
        df[!, end], Matrix(df[!, 1:(end-1)])
    else
        for (k, out) in pairs(df)
            @series begin
                cols = valuecols(df)
                N = length(cols)
                seriestype --> :scatter
                xguide := cols[end]
                label := reshape(string.(cols[1:(end-1)]), 1, N-1) .* " " .* string(NamedTuple(k))
                out[!, end], Matrix(out[!, (end-N):(end-1)])
            end
        end
    end
end

export bin, binscatter, binscatter!, fe, @formula

end
