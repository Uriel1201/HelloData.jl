module HelloData

using TOML, Arrow, SQLite, Tables, DBInterface, CSV


function getconn end
function registertable! end
function insertquery end
function tablenames end
function toarrow end


"""
    function pushct!(ct::NamedTuple{names, <:Tuple{Vararg{<:Vector}}},
        nt::NamedTuple{names}
    ) where{names}
Append a new `NamedTuple` `nt` to `ct`, a `NamedTuple` of vectors with the same keys as `nt`.
Each value of `nt` is added to the corresponding vector of `ct` using `push!`

# Return
- Returns the modified `ct`.

# Example
```julia
julia> ct = NamedTuple{(:id, :name)}((Vector{Int64}(), Vector{String}()))
julia> nt = (id = 1, name = "Margarita")
julia> pushct!(ct, nt)

(id = [1], name = ["Margarita"])
```
"""
function pushct!(ct::NamedTuple{names, <:Tuple{Vararg{<:Vector}}},
    nt::NamedTuple{names}
) where{names}
    for k in keys(ct)
        push!(ct[k], nt[k])
    end
    return ct
end #pushct!

include("schemas.jl")

include("sqlitedbs.jl")

println("[Julia] Hello, Data!, We are ready")

end # module HelloData
