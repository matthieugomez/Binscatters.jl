module Binscatters

using Statistics
using CategoricalArrays
using DataFrames
using FixedEffectModels
using RecipesBase

"""
    binscatter(df::Union{DataFrame, GroupedDataFrame}, f::FormulaTerm, ngroups::Integer; 
                weights::Union{Symbol, Nothing} = nothing, kind::Union{Symbol, Nothing} = nothing,
                kwargs...)

Outputs a binned scatterplot

### Arguments
* `df`: a DataFrame or a GroupedDataFrame
* `f`: A formula created using [`@formula`](@ref). The variable(s) in the left-hand side are on the y-axis. The first variable in the right-hand side is on the x-axis. The other variables are controls.
* `ngroups`: Number of bins

### Keyword arguments
* `weights`: A symbol for weights
* `kind`: The type of line. `:connect` connects the bins, `:lfit` plots a regression line, `nothing` does not plot lines 
* `kwargs...`: Additional attributes for [`Plots`](@ref)

### Examples
```julia
using DataFrames, Binscatters, RDatasets, Plots
df = dataset("plm", "Cigar")
binscatter(df, @formula(Sales ~ Price))

# Change the number of bins
binscatter(df, @formula(Sales ~ Price), 10)

# Residualize the y and x variables w.r.t. controls
binscatter(df, @formula(Sales ~ Price + NDI))
binscatter(df, @formula(Sales ~ Price + fe(Year)))

# Plot multiple variables on the y-axis
binscatter(df, @formula(Sales + NDI ~ Price))

# binscatter by groups
df.Post70 = df.Year .>= 70
binscatter(groupby(df, :Post70), @formula(Sales ~ Price))
```
"""
binscatter

function bin(df::AbstractDataFrame, @nospecialize(f::FormulaTerm), ngroups::Integer = 20; 
            weights::Union{Symbol, Nothing} = nothing)
    df = partial_out(df, _shift(f); weights = weights, align = false, add_mean = true)[1]
    cols = names(df)
    df.__cut = cut(df[!, end], ngroups; allowempty = true)
    df = groupby(df, :__cut)
    combine(df, cols .=> mean .=> cols; keepkeys = false)
end

function bin(df::GroupedDataFrame, @nospecialize(f::FormulaTerm), ngroups::Integer = 20; 
            weights::Union{Symbol, Nothing} = nothing)
    combine(d -> bin(d, f, ngroups; weights = weights), df; ungroup = false)
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

#user recipe: same thing as @userplot Binscatter
mutable struct Binscatter
    args
end
binscatter(args...; kwargs...) = RecipesBase.plot(Binscatter(args); kwargs...)
binscatter!(args...; kwargs...) = RecipesBase.plot!(Binscatter(args); kwargs...)

@recipe function f(bs::Binscatter; weights = nothing, kind = nothing)
    df = bin(bs.args...; weights = weights)
    if df isa DataFrame
        cols = names(df)
        N = length(cols)
        x = df[!, end]
        Y = Matrix(df[!, 1:(end-1)])
        @series begin
            if kind == :connect
                markershape --> :auto
            else
                seriestype --> :scatter
            end
            markerstrokealpha --> 0.0
            xguide --> cols[end]
            label --> reshape(cols[1:(end-1)], 1, N-1)
            x, Y
        end
        if kind == :lfit
            if size(Y, 2) > 1
                linecolor := :black
            end
            X = hcat(ones(length(x)), x)
            β = (X'X) \ (X'Y)
            @series begin
                xguide --> cols[end]
                label := nothing
                x, X * β
            end
        end
    else
        for (k, out) in pairs(df)
            cols = string.(valuecols(df))
            N = length(cols)
            x = out[!, end]
            Y = Matrix(out[!, (end-(N-1)):(end-1)])
            @series begin
                if kind == :connect
                    markershape --> :auto
                else
                    seriestype --> :scatter
                end
                markerstrokealpha --> 0.0
                xguide --> cols[end]
                label --> reshape(cols[1:(end-1)], 1, N-1) .* " " .* string(NamedTuple(k))
                x, Y
            end
        end
        # to get right color for first one, needs to do that
        if kind == :lfit
            for (k, out) in pairs(df)
                cols = string.(valuecols(df))
                N = length(cols)
                x = out[!, end]
                Y = Matrix(out[!, (end-(N-1)):(end-1)])
                X = hcat(ones(length(x)), x)
                β = (X'X) \ (X'Y)
                @series begin
                    linecolor := :black
                    xguide --> cols[end]
                    label := nothing
                    x, X * β
                end
            end
        end
    end
end


export bin, binscatter, binscatter!, fe, @formula

end
