module Binscatters

using DataFrames
using Statistics
using FixedEffects
using FixedEffectModels
using FillArrays
using Reexport

function residualize(df::AbstractDataFrame, @nospecialize(f::FormulaTerm); weights::Union{Symbol, Nothing} = nothing)

    if  (ConstantTerm(0) ∉ FixedEffectModels.eachterm(f.rhs)) & (ConstantTerm(1) ∉ FixedEffectModels.eachterm(f.rhs))
        f = FormulaTerm(f.lhs, tuple(ConstantTerm(1), FixedEffectModels.eachterm(f.rhs)...))
    end
    formula = f
    has_weights = weights != nothing

    # create a dataframe without missing values & negative weights
    all_vars = StatsModels.termvars(formula)
    esample = completecases(df, all_vars)
    if has_weights
        esample .&= .!ismissing.(df[!, weights]) .& (df[!, weights] .> 0)
    end

    fes, ids, formula = FixedEffectModels.parse_fixedeffect(df, formula)
    has_fes = !isempty(fes)

    nobs = sum(esample)
    (nobs > 0) || throw("sample is empty")
    # Compute weights
    if has_weights
        weights = Weights(convert(Vector{Float64}, view(df, esample, weights)))
    else
        weights = Weights(Ones{Float64}(sum(esample)))
    end
    all(isfinite, weights) || throw("Weights are not finite")

    has_intercept = FixedEffectModels.hasintercept(formula)
    has_fe_intercept = false
    if has_fes
        if any(fe.interaction isa Ones for fe in fes)
            has_fe_intercept = true
        end
        fes = FixedEffect[FixedEffectModels._subset(fe, esample) for fe in fes]
        feM = AbstractFixedEffectSolver{Float64}(fes, weights, Val{:cpu})
    end

    # Compute residualized Y
    vars = unique(StatsModels.termvars(formula))
    subdf = Tables.columntable((; (x => disallowmissing(view(df[!, x], esample)) for x in vars)...))
    formula_schema = apply_schema(formula, schema(formula, subdf), FixedEffectModel, has_fe_intercept)

    out = response(formula_schema, subdf)
    if out isa Tuple
        Y = convert(Matrix{Float64}, hcat(out...))
    else
        Y = convert(Vector{Float64}, out)
    end
    all(isfinite, Y) || throw("Some observations for the dependent variable are infinite")

    # Obtain X
    X = convert(Matrix{Float64}, modelmatrix(formula_schema, subdf))
    all(isfinite, X) || throw("Some observations for the exogeneous variables are infinite")

    Y = hcat(Y, X[:, 1])
    X = X[:, 2:end]

    response_name, coef_names = coefnames(formula_schema)
    if !(coef_names isa Vector)
        coef_names = typeof(coef_names)[coef_names]
    end

    if has_intercept
        response_names = vcat(response_name, coef_names[2])
    else
        response_names = vcat(response_name, coef_names[1])
    end


    m = mean(Y, dims = 1)
    if has_fes
        Y, b, c = solve_residuals!(Y, feM)
        X, b, c = solve_residuals!(X, feM)
    end

    Y .= Y .* sqrt.(weights)
    X .= X .* sqrt.(weights)
    # Compute residuals
    if size(X, 2) > 0
        residuals = Y .- X * (X \ Y)
    else
        residuals = Y
    end

    # rescale residuals
    residuals .= (residuals .+ m) ./ sqrt.(weights)

    # Return a dataframe
    df = DataFrame()
    j = 0
    for y in response_names
        j += 1
        df[!, Symbol(y)] = residuals[:, j]
    end
    return df
end

"""
Return a DataFrame that residualize and collapse 

### Arguments
* `df`: a DataFrame
* `FormulaTerm`: A formula created using [`@formula`](@ref)
* `weights`: A symbol for weights
* `n`: Number of groups

### Examples
```julia
using Binscatters
df = dataset("plm", "Cigar")
binscatter(df, @formula(Sales ~ NDI + fe(State))
binscatter(df, @formula(Sales ~ NDI + Price + fe(State))
binscatter(df, @formula(Sales + Price ~ NDI + fe(State))
```
"""

function binscatter(df::AbstractDataFrame, f::FormulaTerm; weights::Union{Symbol, Nothing} = nothing, n = 20)
    df = residualize(df, f; weights = weights)
    cols = names(df)
    df.x_cut = cut(df[end], n)
    df = groupby(df, :x_cut)
    df = combine(df, cols .=> mean∘skipmissing .=> cols; keepkeys = false)
end

function binscatter(df::GroupedDataFrame, f::FormulaTerm; weights::Union{Symbol, Nothing} = nothing, n = 20)
    combine(d -> binscatter(d, f; weights = weights, n = n), df; ungroup = false)
end

export binscatter, fe, @formula

end
