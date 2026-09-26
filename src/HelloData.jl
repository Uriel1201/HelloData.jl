module HelloData

using TOML

export Config, SQLiteDBS

greet() = "[Julia] Hello, Data!"

include("config.jl")

include("schemas.jl")

include("sqlite_dbs.jl")

end # module HelloData
