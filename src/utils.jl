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





# simplified version of CategoricalArrays' cut

function _cut(x::AbstractArray, ngroups::Integer)
    xnm = eltype(x) >: Missing ? skipmissing(x) : x
    breaks = Statistics.quantile(xnm, (1:ngroups-1)/ngroups)
    _cut(x, breaks)
end

function _cut(x::AbstractArray, breaks::AbstractVector)
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

