module HelloData

using TOML

greet() = "[Julia] Hello, Data!"
include("config.jl")
include("schemas.jl")

end # module HelloData
