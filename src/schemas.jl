tomlpath = joinpath(@__DIR__, "..", "Schemas.toml")

const TYPEMAP = Dict{String, Type}(
    "INT0"  => Int64,
    "INT1"  => Union{Int64, Missing},
    "TEXT0" => String,
    "TEXT1" => Union{String, Missing},
    "REAL0" => Float64,
    "REAL1" => Union{Float64, Missing}
)


"""
    parse_type_string(typestr::String)::Type
Converts a String into a Julia Type code.
The content of the string is predetermined by TYPEMAP
# Arguments
- `typestr::String`: A String containing the Julia Type to be parsed
# Return 
- the Julia Type parsed from the String 
"""
function parse_type_string(typestr::String)::Type
    try
        return TYPEMAP[typestr]
    catch e
        error("Failed to parse type '$typestr' defined in TOML. Error: $e")
    end
end


"""
    appendschema!(table::String,
        schema::Base.Iterators.Zip{Tuple{Vector{String}, Vector{String}}};
        description::String="") -> Nothing
Updates Schemas.toml by adding specifications for a new table.
# Arguments 
- `table::String`: The name of a new table to be added to `Schemas.toml`
- `schema::Base.Iterators.Zip`: A Tuple iterator containing the column names and
                                their types. The types are provided as strings and 
                                represent type information from the database 
                                not julia types.
- `description::String`: A short description about the new table.
"""
function appendschema!(table::String,
    schema::Base.Iterators.Zip{Tuple{Vector{String}, Vector{String}}};
    description::String=""
)
    schemas = isfile(tomlpath) ? TOML.parsefile(tomlpath) : Dict{String, Any}()
    schemas[table] = Dict(
            "description" => description,
            "columns" => [Dict("name" => a, "type" => b) for (a,b) in schema],
    )
    open(tomlpath, "w") do io
        TOML.print(io, schemas)
    end
end


"""
    schema(table::String)::Vector{Pair{Symbol, Type}}
Returns the column names and their corresponding Julia types defined
in the table schema stored in Schemas.toml.
# Arguments
- `table::String`: A table name defined inside Schemas.toml
# Return 
- A vector of pairs containing the table's metadata
"""
function schema(table::String)::Vector{Pair{Symbol, Type}}
    schemas = TOML.parsefile(tomlpath)
    if !haskey(schemas, table)
        error("Table '$table' not found in Schemas.toml")
    end
    println("""Table: $table -> $(schemas[table]["description"])""")
    return map(schemas[table]["columns"]) do col
        Symbol(col["name"]) => parse_type_string(col["type"])
    end
end
