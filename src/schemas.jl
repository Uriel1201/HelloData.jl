using TOML

schemas_path = joinpath(@__DIR__, "..", "Schemas.toml")

const TABLES_TOML = TOML.parsefile(schemas_path)
        
"""
```julia
parse_type_string(type_str::String)::Type
```
Converts a String containing Julia code into an expression (Expr).
Then evaluates the expression as Julia code in the module specified by @__MODULE__.
# Arguments
- `type_str::String`: A String containing the Julia Type to be parsed
# Return 
- the Julia Type parsed from the String 
"""
function parse_type_string(type_str::String)::Type
    try
        return Core.eval(@__MODULE__, Meta.parse(type_str))
    catch e
        error("Failed to parse type '$type_str' defined in TOML. Error: $e")
    end
end


"""
```julia
my_data_types(table::String)::Vector{Pair{Symbol, Type}}
```
Returns the column names and their corresponding Julia types defined
in the table schema stored in a Dictionary.
# Arguments
- `table::String`: A table name defined inside Schemas.toml
# Return 
- A vector of pairs containing the table's metadata
"""
function my_data_types(table::String)::Vector{Pair{Symbol, Type}}
    schemas_toml = Dict(table => content["columns"] for (table, content) in TABLES_TOML)
    if !haskey(schemas_toml, table)
        error("Table '$table' not found in Schemas.toml")
    end
    return map(schemas_toml[table]) do col
        Symbol(col["name"]) => parse_type_string(col["type"])
    end
end
