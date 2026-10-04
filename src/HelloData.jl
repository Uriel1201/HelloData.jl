module HelloData

using TOML
export SQLiteDBS, datadir

datadir() = get(ENV, "DATA_DIR", nothing)

include("schemas.jl")
include("sqlitedbs.jl")
println("[Julia] Hello, Data!, We are ready")

end # module HelloData
