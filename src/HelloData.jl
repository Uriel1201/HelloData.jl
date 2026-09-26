module HelloData

using TOML

greet() = "[Julia] Hello, Data!"
include("config.jl")
include("schemas.jl")
include("sqlite_dbs")

export Config, SQLiteDBS

end # module HelloData
