# Internal helper: weighted mean that handles missing values in x
function _wmean(x, w)
    mask = .!ismissing.(x)
    mean(collect(x[mask]), Weights(w[mask]))
end

function bin(df::AbstractDataFrame, xvar::Symbol, n::Integer = 20; weights::Union{Symbol, Nothing} = nothing)
    cols = propertynames(df)
    # Drop rows with missing x (and missing weights if applicable)
    esample = .!ismissing.(df[!, xvar])
    if weights !== nothing
        esample .&= .!ismissing.(df[!, weights])
    end
    df = df[esample, :]
    # Compute bin assignments
    if weights === nothing
        df.__cut = cut(df[!, xvar], n)
    else
        df.__cut = cut(df[!, xvar], n, Weights(df[!, weights]))
    end
    df = groupby(df, :__cut, sort = true)
    # Aggregate
    agg_cols = weights === nothing ? cols : setdiff(cols, [weights])
    if weights === nothing
        return combine(df, (col => mean ∘ skipmissing => col for col in agg_cols)...; keepkeys = false)
    else
        return combine(df, ([col, weights] => _wmean => col for col in agg_cols)...; keepkeys = false)
    end
end


function bin(df::AbstractDataFrame, @nospecialize(f::FormulaTerm), n::Integer = 20;
            weights::Union{Symbol, Nothing} = nothing)
    if _no_controls(f) && _all_plain_terms(f)
        # Short-circuit: no need for partial_out
        lhs_terms = f.lhs isa Tuple ? collect(f.lhs) : [f.lhs]
        rhs_terms = f.rhs isa Tuple ? collect(f.rhs) : [f.rhs]
        xterm = first(t for t in rhs_terms if !(t isa ConstantTerm))
        xvar = xterm.sym
        yvars = [t.sym for t in lhs_terms]
        all_cols = [yvars; xvar]
        if weights !== nothing
            push!(all_cols, weights)
        end
        sub = df[!, unique(all_cols)]
        return bin(sub, xvar, n; weights = weights)
    else
        f_shifted = _shift(f)
        df2 = partial_out(df, f_shifted; weights = weights, align = true, add_mean = true)[1]
        xvar = propertynames(df2)[end]
        if weights !== nothing
            df2[!, weights] = df[!, weights]
        end
        return bin(df2, xvar, n; weights = weights)
    end
end

function bin(df::GroupedDataFrame, @nospecialize(f::FormulaTerm), n::Integer = 20;
            weights::Union{Symbol, Nothing} = nothing)
    combine(d -> bin(d, f, n; weights = weights), df; ungroup = false)
end

function bin(df, @nospecialize(f::FormulaTerm), n::Integer = 20;
            weights::Union{Symbol, Nothing} = nothing)
    bin(DataFrame(df), f, n; weights = weights)
end


# Simplified version of CategoricalArrays' cut, supporting weights
function cut(x::AbstractArray, ngroups::Integer)
    ngroups = min(ngroups, length(unique(x)))
    ngroups <= 1 && return ones(UInt32, length(x))
    breaks = unique(Statistics.quantile(x, (1:ngroups-1)/ngroups))
    cut(x, breaks)
end

function cut(x::AbstractArray, ngroups::Integer, weights::AbstractWeights)
    ngroups = min(ngroups, length(unique(x)))
    ngroups <= 1 && return ones(UInt32, length(x))
    breaks = unique(StatsBase.quantile(x, weights, (1:ngroups-1)/ngroups))
    cut(x, breaks)
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

# Internal: assign each element of X to a bin index based on sorted breaks.
# Returns 0 for missing values. The last break is treated as inclusive on the right.
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


# Helper: check if formula has no control variables (only one non-constant RHS term)
function _no_controls(@nospecialize(f::FormulaTerm))
    rhs = f.rhs isa Tuple ? f.rhs : (f.rhs,)
    count(x -> !(x isa ConstantTerm), rhs) <= 1
end

# Helper: check if all terms in the formula are plain Term (not FunctionTerm, fe, etc.)
function _all_plain_terms(@nospecialize(f::FormulaTerm))
    lhs = f.lhs isa Tuple ? f.lhs : (f.lhs,)
    rhs = f.rhs isa Tuple ? f.rhs : (f.rhs,)
    all(t -> t isa Term, lhs) && all(t -> (t isa Term) || (t isa ConstantTerm), rhs)
end

# Transform lhs ~ x + rhs to lhs + x ~ rhs
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
