module HelloData

using TOML, Arrow, SQLite, Tables, DBInterface, CSV

include("schemas.jl")

include("sqlitedbs.jl")


function toarrow end

println("[Julia] Hello, Data!, We are ready")

end # module HelloData
