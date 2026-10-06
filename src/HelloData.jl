module HelloData

using TOML

include("schemas.jl")

export SQLiteDBS, datadir

include("sqlitedbs.jl")

datadir() = get(ENV, "DATA_DIR", nothing)

using .SQLiteDBS, Arrow, SQLite

function toarrow end


println("[Julia] Hello, Data!, We are ready")

end # module HelloData
