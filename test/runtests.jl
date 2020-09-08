
using CSV, DataFrames,  Test, Binscatters
df = DataFrame(CSV.File(joinpath(dirname(pathof(Binscatter)), "../dataset/Cigar.csv")))
df.id1 = df.State
df.id2 = df.Year
df.pid1 = categorical(df.id1)
df.pid2 = categorical(df.id2)

df.mid1 = div.(df.id1, Ref(10))
df.y = df.Sales
df.x1 = df.Price
df.z1 = df.Pimin
df.x2 = df.NDI
df.w = df.Pop


binscatter(df, @formula(y~x1))
binscatter(df, @formula(y~x1), weights = :w)
binscatter(df, @formula(y+x2~x1))
binscatter(groupby(df, :id1), @formula(y+x2~x1))