using TOML

struct Column
    name::String
    sqltype::String
    nullable::Bool
    primarykey::Bool
end


struct TableSchema
    tablename::String
    description::String
    columns::Vector{Pair{Symbol, Type}}
end

    
function Column(d::Dict)
    return Column(
        d["name"],
        d["sqltype"],
        d["nullable"],
        d["primarykey"],
    )
end


function TableSchema(table::String, d::Dict)
    return TableSchema(
        table,
        d["description"],
        [Symbol(c.name) => parse_type_string(c.type, 
                               c.nullable
                           ) for c in schemaspecs(d)
        ],
    )
end

    
function Base.Dict(c::Column)
    return Dict{String, Any}(
        "name"        => c.name,
        "sqltype"     => c.sqltype,
        "nullable"    => c.nullable,
        "primarykey"  => c.primarykey,
    )
end


const BASETYPES = Dict{String, Type}(
    "INT"  => Int64,
    "TEXT" => String,
    "REAL" => Float64,
)


function schemaspecs(d::Dict)
    return [Column(coldict) for  coldictoin ]
end


"""
    appendschema!(table::String,
        columns::Vector{ColumnSpec};
        description::String=""
    ) -> Nothing
Updates one `toml` file by adding specifications for a new table.
# Arguments 
- `table::String`               : The name of a new table to be added to `Schemas.toml`.
- `columns::Vector{ColumnSpec}` : A Vector of `Column`.
- `tomlpath::String`            : The directory of the `toml` file.
- `description::String`         : A short description about the table.
"""
function appendschema!(table::String,
    columns::Vector{ColumnSpec},
    tomlpath::String;
    description::String=""
)
    schemas = isfile(tomlpath) ? TOML.parsefile(tomlpath) : Dict{String, Any}()
    schemas[table] = Dict(
            "description" => description,
            "columns" => [Dict(c) for c in columns],
    )
    open(tomlpath, "w") do io
        TOML.print(io, schemas)
    end
end
    

"""
    parse_type_string(typestr::String,
        nullable::Bool
    )::Type
Converts a String into a Julia Type code.
The content of the string is predetermined by TYPEMAP
# Arguments
- `base::String`   : A String containing the Julia `Type` to be parsed.
- `nullable::Bool` : Specifies wether a column accepts `missing` values.
# Return 
- the Julia Type parsed from the String 
"""
function parse_type_string(base::String, nullable::Bool)::Type
    haskey(BASETYPES, base) || error("Type unknown: $base")
    T = BASETYPES[base]
    return nullable ? Union{T, Missing} : T
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
