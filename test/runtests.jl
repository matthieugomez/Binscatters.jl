using CSV, DataFrames, Test, Plots, Binscatters
df = DataFrame(CSV.File(joinpath(dirname(pathof(Binscatters)), "../dataset/Cigar.csv")))

@testset "Binscatters.jl" begin

@testset "bin function" begin
    @testset "basic" begin
        out = bin(df, @formula(Sales ~ Price))
        @test issorted(out.Price)
        @test minimum(out.Price) >= minimum(df.Price)
        @test maximum(out.Price) <= maximum(df.Price)
        @test nrow(out) == 20
    end

    @testset "log transforms" begin
        out = bin(df, @formula(Sales ~ log(Price)))
        @test issorted(out."log(Price)")
        @test minimum(out."log(Price)") >= log(minimum(df.Price))
        @test maximum(out."log(Price)") <= log(maximum(df.Price))
        out = bin(df, @formula(log(Sales) ~ log(Price)))
        @test minimum(out."log(Sales)") >= log(minimum(df.Sales))
        @test maximum(out."log(Sales)") <= log(maximum(df.Sales))
    end

    @testset "weighted" begin
        out = bin(df, @formula(Sales ~ Price), weights = :Pop)
        @test minimum(out.Price) >= minimum(df.Price)
        @test maximum(out.Price) <= maximum(df.Price)
        @test nrow(out) == 20
    end

    @testset "custom n" begin
        out = bin(df, @formula(Sales ~ Price), 10)
        @test nrow(out) == 10
    end

    @testset "controls" begin
        out = @test_nowarn bin(df, @formula(Sales ~ Price + NDI))
        @test nrow(out) == 20
        out = @test_nowarn bin(df, @formula(Sales ~ Price + fe(State)))
        @test nrow(out) == 20
    end

    @testset "multiple y" begin
        out = @test_nowarn bin(df, @formula(Sales + NDI ~ Price))
        @test :Sales in propertynames(out)
        @test :NDI in propertynames(out)
        @test :Price in propertynames(out)
    end

    @testset "missing x" begin
        df2 = copy(df)
        df2.Price_missing = ifelse.(df2.Price .>= 30, df2.Price, missing)
        out = @test_nowarn bin(df2, @formula(Sales ~ Price_missing))
        @test !any(ismissing, out.Price_missing)
    end

    @testset "grouped" begin
        out = @test_nowarn bin(groupby(df, :State), @formula(Sales ~ Price))
        @test out isa GroupedDataFrame
    end
end

@testset "edge cases" begin
    @testset "small n" begin
        out = bin(df, @formula(Sales ~ Price), 2)
        @test nrow(out) == 2
        @test issorted(out.Price)
    end

    @testset "n = 1" begin
        out = bin(df, @formula(Sales ~ Price), 1)
        @test nrow(out) == 1
    end

    @testset "n > unique values" begin
        small = df[1:3, :]
        out = @test_nowarn bin(small, :Price, 100)
        @test nrow(out) >= 1
        @test nrow(out) <= 3
    end

    @testset "constant x column" begin
        df_const = DataFrame(x = fill(42.0, 100), y = randn(100))
        out = @test_nowarn bin(df_const, :x, 20)
        @test nrow(out) == 1
    end

    @testset "weighted with missing y" begin
        df_wm = copy(df)
        df_wm.Sales_miss = ifelse.(df_wm.Sales .> 100, df_wm.Sales, missing)
        out = @test_nowarn bin(df_wm, @formula(Sales_miss ~ Price), weights = :Pop)
        @test nrow(out) > 0
        @test !any(ismissing, out.Price)
    end
end

@testset "plots recipe" begin
    @testset "basic scatter" begin
        p = @test_nowarn binscatter(df, @formula(Sales ~ Price))
        @test p isa Plots.Plot
    end

    @testset "scatterpath" begin
        p = @test_nowarn binscatter(df, @formula(Sales ~ Price), seriestype = :scatterpath)
        @test p isa Plots.Plot
    end

    @testset "linearfit" begin
        p = @test_nowarn binscatter(df, @formula(Sales ~ Price), seriestype = :linearfit)
        @test p isa Plots.Plot
    end

    @testset "log transform" begin
        p = @test_nowarn binscatter(df, @formula(log(Sales) ~ log(Price)))
        @test p isa Plots.Plot
    end

    @testset "multiple y" begin
        p = @test_nowarn binscatter(df, @formula(Sales + NDI ~ Price))
        @test p isa Plots.Plot
        p = @test_nowarn binscatter(df, @formula(Sales + NDI ~ Price), seriestype = :scatterpath)
        @test p isa Plots.Plot
        p = @test_nowarn binscatter(df, @formula(Sales + NDI ~ Price), seriestype = :linearfit)
        @test p isa Plots.Plot
    end

    @testset "with controls" begin
        p = @test_nowarn binscatter(df, @formula(Sales ~ Price + fe(State)))
        @test p isa Plots.Plot
        p = @test_nowarn binscatter(df, @formula(Sales ~ Price), weights = :Pop)
        @test p isa Plots.Plot
        p = @test_nowarn binscatter(df, @formula(Sales + NDI ~ Price))
        @test p isa Plots.Plot
        p = @test_nowarn binscatter(df, @formula(Sales ~ Price + NDI))
        @test p isa Plots.Plot
    end

    @testset "grouped" begin
        df2 = copy(df)
        df2.dummy = df2.State .>= 25
        p = @test_nowarn binscatter(groupby(df2, :dummy), @formula(Sales ~ Price))
        @test p isa Plots.Plot
        p = @test_nowarn binscatter(groupby(df2, :dummy), @formula(Sales ~ Price), seriestype = :scatterpath)
        @test p isa Plots.Plot
        p = @test_nowarn binscatter(groupby(df2, :dummy), @formula(Sales ~ Price), seriestype = :linearfit)
        @test p isa Plots.Plot
    end

    @testset "grouped multiple y" begin
        df2 = copy(df)
        df2.dummy = df2.State .>= 25
        p = @test_nowarn binscatter(groupby(df2, :dummy), @formula(Sales + NDI ~ Price))
        @test p isa Plots.Plot
        p = @test_nowarn binscatter(groupby(df2, :dummy), @formula(Sales + NDI ~ Price), seriestype = :scatterpath)
        @test p isa Plots.Plot
        p = @test_nowarn binscatter(groupby(df2, :dummy), @formula(Sales + NDI ~ Price), seriestype = :linearfit)
        @test p isa Plots.Plot
    end
end

end  # top-level testset
