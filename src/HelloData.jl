module HelloData

using TOML, DotEnv

greet() = "[Julia] Hello, Data!"
include("config.jl")
include("schemas.jl")

end # module HelloData
