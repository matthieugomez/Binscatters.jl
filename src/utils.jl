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


@recipe function f(::Type{Val{:linearfit}}, x, y, z)
    seriestype := :scatter
    @series begin
        x := x
        y := y
        seriestype := :scatter
        ()
    end
    X = hcat(ones(length(x)), x)
    yhat = X * (X'X \ X'y)
    @series begin
        seriestype := :path
        label := ""
        primary := false
        x := x
        y := yhat
        ()
    end
    primary := false
    ()
end