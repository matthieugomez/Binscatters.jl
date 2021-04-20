function bin(df::AbstractDataFrame, @nospecialize(f::FormulaTerm), n::Integer = 20; 
            weights::Union{Symbol, Nothing} = nothing)
    df = partial_out(df, _shift(f); weights = weights, align = false, add_mean = true)[1]
    cols = names(df)
    df.__cut = cut(df[!, end], n)
    df = groupby(df, :__cut, sort = true)
    out = combine(df, cols .=> mean .=> cols; keepkeys = false)
    return out
end

function bin(df::GroupedDataFrame, @nospecialize(f::FormulaTerm), n::Integer = 20; 
            weights::Union{Symbol, Nothing} = nothing)
    combine(d -> bin(d, f, n; weights = weights), df; ungroup = false)
end

function bin(df, @nospecialize(f::FormulaTerm), n::Integer = 20; 
            weights::Union{Symbol, Nothing} = nothing)
    bin(DataFrame(df), f, n; weights = weights)
end


# simplified version of CategoricalArrays' cut
function cut(x::AbstractArray, ngroups::Integer)
    xnm = eltype(x) >: Missing ? skipmissing(x) : x
    breaks = Statistics.quantile(xnm, (1:ngroups-1)/ngroups)
    cut(x, breaks)
end

function cut(x::AbstractArray, breaks::AbstractVector)
    xnm = eltype(x) >: Missing ? skipmissing(x) : x
    min_x, max_x = extrema(xnm)
    if first(breaks) > min_x
        breaks = [min_x; breaks]
    end
    if last(breaks) < max_x
        breaks = [breaks; max_x]
    end
    refs = Array{UInt32}(undef, size(x))
    fill_refs!(refs, x, breaks)
    return refs
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
    i = findfirst(x -> x isa Term, rhs)
    FormulaTerm(tuple(lhs..., rhs[i]), Tuple(term for term in rhs if term != rhs[i]))
end


