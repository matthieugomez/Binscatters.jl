
using CSV, DataFrames, Test, Plots, Binscatter
df = DataFrame(CSV.File(joinpath(dirname(pathof(Binscatter)), "../dataset/Cigar.csv")))
df.id1 = df.State
df.y = df.Sales
df.x1 = df.Price
df.z1 = df.Pimin
df.x2 = df.NDI
df.w = df.Pop


out = bin(df, @formula(y~x1))
@test minimum(out.x1) >= minimum(df.x1)
@test maximum(out.x1) <= maximum(df.x1)
bin(df, @formula(y ~ x1 + fe(id1)))
bin(df, @formula(y~x1), weights = :w)
bin(df, @formula(y+x2~x1))
bin(df, @formula(y~x1+x2))
bin(groupby(df, :id1), @formula(y~x1))


binscatter(df, @formula(y ~ x1 + fe(id1)))
binscatter(df, @formula(y~x1), weights = :w)
binscatter(df, @formula(y+x2~x1))
binscatter(df, @formula(y~x1+x2))
binscatter(groupby(df, :id1), @formula(y~x1))
binscatter(groupby(df, :id1), @formula(y+x2~x1))