module HelloData

using TOML, Arrow, SQLite

export SQLiteDBS, datadir

include("schemas.jl")
include("sqlitedbs.jl")

datadir() = get(ENV, "DATA_DIR", nothing)

using .SQLiteDBS

function toarrow end

println("[Julia] Hello, Data!, We are ready")

end # module HelloData
