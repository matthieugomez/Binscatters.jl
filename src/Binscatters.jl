module Binscatters

using DataFrames
using Statistics
using FixedEffectModels

"""
Return a DataFrame that (i) residualizes the left hand side and the first variable of the right hand side w.r.t all other variables in the formula (ii) average variables w.r.t bins of the first variable of the right-hand-side

### Arguments
* `df`: a DataFrame
* `FormulaTerm`: A formula created using [`@formula`](@ref)
* `weights`: A symbol for weights
* `n`: Number of groups

### Examples
```julia
using Binscatters, RDatasets
df = dataset("plm", "Cigar")
binscatter(df, @formula(Sales ~ NDI))
binscatter(df, @formula(Sales ~ NDI + fe(State)))
binscatter(df, @formula(Sales ~ NDI + Price + fe(State)))
binscatter(df, @formula(Sales + Price ~ NDI + fe(State)))
```
"""

function binscatter(df::AbstractDataFrame, @nospecialize(f::FormulaTerm); weights::Union{Symbol, Nothing} = nothing, n = 20)
    df = partial_out(df, translate(f); weights = weights, align = false, add_mean = true)[1]
    cols = names(df)
    df.__cut = cut(df[!, end], n; allowempty = true)
    df = groupby(df, :__cut)
    combine(df, cols .=> mean .=> cols; keepkeys = false)
end

function binscatter(df::GroupedDataFrame, @nospecialize(f::FormulaTerm); weights::Union{Symbol, Nothing} = nothing, n = 20)
    df = combine(d -> binscatter(d, f; weights = weights, n = n), df)
    df = stack(df, names(df, 2:size(df, 2)); 
        variable_name = :__variable, value_name = :__value, variable_eltype = String)
    df.__variable = names(df, 1) .* "=" .* string.(df[!, 1]) .* df.__variable 
    select!(df, :__variable, :__value)
    transform!(groupby(df, :__variable), :__value => (x -> 1:length(x)) => :length)
    unstack(df, :__variable, :__value)
end

function translate(@nospecialize(formula::FormulaTerm))
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


export binscatter, fe, @formula

end
