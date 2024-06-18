function bin(df::AbstractDataFrame, n::Integer = 20; by::Symbol, weights::Union{Symbol, Nothing} = nothing)
    df = dropmissing(df)
    cols = propertynames(df)
    if weights === nothing
        df.__cut = cut(df[!, by], n)
        df = groupby(df, :__cut, sort = true)
        return combine(df, (col => mean => col for col in cols)...; keepkeys = false)
    else
        df.__cut = cut(df[!, by], n, df[!, weights])
        df = groupby(df, :__cut, sort = true)
        cols = setdiff(cols, [weights])
        return combine(df, ([col, weights] => ((x, w) -> mean(x, Weights(w))) => col for col in cols)...; keepkeys = false)
    end
end

#transform lhs ~ x + rhs to lhs + x ~ rhs
function _shift(@nospecialize(formula::FormulaTerm))
    lhs = formula.lhs
    rhs = formula.rhs
    if !(lhs isa Tuple)
        lhs = (lhs,)
    end
    if !(rhs isa Tuple)
        rhs = (rhs,)
    end
    i = findfirst(x -> !(x isa ConstantTerm), rhs)
    FormulaTerm(tuple(lhs..., rhs[i]), Tuple(term for term in rhs if term != rhs[i]))
end


function bin(df::GroupedDataFrame, @nospecialize(f::FormulaTerm), n::Integer = 20; 
            weights::Union{Symbol, Nothing} = nothing)
    combine(d -> bin(d, f, n; weights = weights), df; ungroup = false)
end

function bin(df, @nospecialize(f::FormulaTerm), n::Integer = 20; 
            weights::Union{Symbol, Nothing} = nothing)
    bin(DataFrame(df), f, n; weights = weights)
end

function bin(df::AbstractDataFrame, @nospecialize(f::FormulaTerm), n::Integer = 20; 
            weights::Union{Symbol, Nothing} = nothing)
    df2 = partial_out(df, _shift(f); weights = weights, align = true, add_mean = true)[1]
    by = propertynames(df2)[end]
    if weights !== nothing
        df2[!, weights] = df[!, weights]
    end
    bin(df2, n; by = by, weights = weights)
end


# simplified version of CategoricalArrays' cut which also includes weights but only operates on non missing
function cut(x::AbstractArray, ngroups::Integer)
    cut(x, Statistics.quantile(x, (1:ngroups-1)/ngroups))
end

function cut(x::AbstractArray, ngroups::Integer, weights::AbstractArray)
    cut(x, StatsBase.quantile(x, Weights(weights), (1:ngroups-1)/ngroups))
end


function cut(x::AbstractArray, breaks::AbstractVector)
    min_x, max_x = extrema(x)
    if first(breaks) > min_x
        breaks = [min_x; breaks]
    end
    if last(breaks) < max_x
        breaks = [breaks; max_x]
    end
    refs = Array{UInt32}(undef, size(x))
    fill_refs!(refs, x, breaks)
end

function fill_refs!(refs::AbstractArray, X::AbstractArray, breaks::AbstractVector)
    upper = last(breaks)
    @inbounds for i in eachindex(X)
        x = X[i]
        if ismissing(x)
            refs[i] = 0
        elseif x == upper
            refs[i] = length(breaks)-1
        else
            refs[i] = searchsortedlast(breaks, x)
        end
    end
    return refs
end





