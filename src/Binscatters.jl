module Binscatters

using DataFrames
using Statistics
using FixedEffectModels
using RecipesBase
using CategoricalArrays

"""
Return a plot after (i) residualizing the left hand side and the first variable of the right hand side w.r.t all other variables in the formula (ii) averaging variables w.r.t bins of the first variable of the right-hand-side

### Arguments
* `df`: a DataFrame or a GroupedDataFrame
* `FormulaTerm`: A formula created using [`@formula`](@ref). The syntax is `@formula(y ~ x + control)` 
* `weights`: A symbol for weights
* `n`: Number of groups
* kwargs...: Plot attributes from Plots

### Examples
```julia
using Revise, Binscatters, RDatasets, Plots
pgfplotsx()
df = dataset("plm", "Cigar")
binscatter(df, @formula(Sales ~ Price))
binscatter(df, @formula(Sales ~ Price), n = 10)
binscatter(df, @formula(Sales ~ Price), n = 10, color = :black)

# More complicated formulas
binscatter(df, @formula(Sales ~ Price + NDI))
binscatter(df, @formula(Sales ~ Price + NDI + fe(Year)))
binscatter(df, @formula(Sales + NDI ~ Price))

# binscatter by groups
df.Year2 = df.Year .>= 70
binscatter(groupby(df, :Year2), @formula(Sales ~ Price + fe(Year)))
df.State2 = df.State .>= 25
binscatter(groupby(df, [:Year2, :State2]), @formula(Sales ~ Price + fe(Year)))
```
"""
binscatter

function bin(df::AbstractDataFrame, @nospecialize(f::FormulaTerm); weights::Union{Symbol, Nothing} = nothing, n = 20)
    df = partial_out(df, _shift(f); weights = weights, align = false, add_mean = true)[1]
    cols = names(df)
    df.__cut = cut(df[!, end], n; allowempty = true)
    df = groupby(df, :__cut)
    combine(df, cols .=> mean .=> cols; keepkeys = false)
end

function bin(df::GroupedDataFrame, @nospecialize(f::FormulaTerm); weights::Union{Symbol, Nothing} = nothing, n = 20, ungroup = true)
    combine(d -> bin(d, f; weights = weights, n = n), df; ungroup = ungroup)
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
@userplot Binscatter
@recipe function f(bs::Binscatter; weights = nothing, n = 20)
    df = bs.args[1]
    f = bs.args[2]
    seriestype --> :scatter
    if df isa DataFrame
        df = bin(df, f; weights = weights, n = n)
        cols = names(df)
        xguide := cols[end]
        N = length(cols)
        label := reshape(cols[1:(end-1)], 1, N-1)
        df[!, end], collect(eachcol(df[!, 1:(N-1)]))
    else
        df = bin(df, f; weights = weights, n = n, ungroup = false)
        for (k, out) in pairs(df)
            @series begin
                cols = valuecols(df)
                xguide := cols[end]
                N = length(cols)
                label := reshape(string.(cols[1:(end-1)]), 1, N-1)  .* " " .* string(NamedTuple(k))
                out[!, end], collect(eachcol(out[!, (end-N):(end-1)]))
            end
        end
    end
end


export bin, binscatter, fe, @formula

end
