
using CSV, DataFrames, Test, Plots, Binscatters
df = DataFrame(CSV.File(joinpath(dirname(pathof(Binscatters)), "../dataset/Cigar.csv")))



out = Binscatters.bin(df, @formula(Sales ~ Price))
@test issorted(out.Price)
@test minimum(out.Price) >= minimum(df.Price)
@test maximum(out.Price) <= maximum(df.Price)
#Binscatters.bin(df, @formula(Sales ~ Price), weights = :w)
#@test minimum(out.Price) >= minimum(df.Price)
#@test maximum(out.Price) <= maximum(df.Price)
Binscatters.bin(df, @formula(Sales ~ Price), 10)
Binscatters.bin(df, @formula(Sales ~ Price + NDI))
Binscatters.bin(df, @formula(Sales ~ Price + fe(State)))
Binscatters.bin(df, @formula(Sales + NDI ~ Price))

Binscatters.bin(groupby(df, :State), @formula(Sales ~ Price))

binscatter(df, @formula(Sales ~ Price))
binscatter(df, @formula(Sales ~ Price), seriestype = :scatterpath)
binscatter(df, @formula(Sales ~ Price), seriestype = :linearfit)


binscatter(df, @formula(Sales + NDI ~ Price))
binscatter(df, @formula(Sales + NDI ~ Price), seriestype = :scatterpath)
binscatter(df, @formula(Sales + NDI ~ Price), seriestype = :linearfit)



binscatter(df, @formula(Sales ~ Price + fe(State)))
binscatter(df, @formula(Sales ~ Price), weights = :Pop)
binscatter(df, @formula(Sales + NDI~ Price))
binscatter(df, @formula(Sales ~ Price + NDI))


df.dummy = df.State .>= 25
binscatter(groupby(df, :dummy), @formula(Sales ~ Price))
binscatter(groupby(df, :dummy), @formula(Sales ~ Price), seriestype = :scatterpath)
binscatter(groupby(df, :dummy), @formula(Sales ~ Price), seriestype = :linearfit)


binscatter(groupby(df, :dummy), @formula(Sales + NDI ~ Price))
binscatter(groupby(df, :dummy), @formula(Sales + NDI ~ Price), seriestype = :scatterpath)
binscatter(groupby(df, :dummy), @formula(Sales + NDI ~ Price), seriestype = :linearfit)
