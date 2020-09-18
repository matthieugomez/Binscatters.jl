
using CSV, DataFrames, Test, Plots, Binscatters
df = DataFrame(CSV.File(joinpath(dirname(pathof(Binscatters)), "../dataset/Cigar.csv")))
df.id1 = df.State
df.y = df.Sales
df.x1 = df.Price
df.z1 = df.Pimin
df.x2 = df.NDI
df.w = df.Pop


out = bin(df, @formula(y~x1))
@test minimum(out.x1) >= minimum(df.x1)
@test maximum(out.x1) <= maximum(df.x1)
#bin(df, @formula(y~x1), weights = :w)
#@test minimum(out.x1) >= minimum(df.x1)
#@test maximum(out.x1) <= maximum(df.x1)
bin(df, @formula(y~x1), 10)
bin(df, @formula(y~x1+x2))
bin(df, @formula(y ~ x1 + fe(id1)))
bin(df, @formula(y+x2~x1))

bin(groupby(df, :id1), @formula(y~x1))

binscatter(df, @formula(y ~ x1))
binscatter(df, @formula(y ~ x1), kind = :connect)
binscatter(df, @formula(y ~ x1), kind = :lfit)


binscatter(df, @formula(y + x2 ~ x1))
binscatter(df, @formula(y + x2 ~ x1), kind = :connect)
binscatter(df, @formula(y + x2 ~ x1), kind = :lfit)



binscatter(df, @formula(y ~ x1 + fe(id1)))
binscatter(df, @formula(y~x1), weights = :w)
binscatter(df, @formula(y+x2~x1))
binscatter(df, @formula(y~x1+x2))


df.dummy = df.id1 .>= 25
binscatter(groupby(df, :dummy), @formula(y~x1))
binscatter(groupby(df, :dummy), @formula(y~x1), kind = :connect)
binscatter(groupby(df, :dummy), @formula(y~x1), kind = :lfit)
