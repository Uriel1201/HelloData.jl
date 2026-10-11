using TOML

"""
    Column(name, sqltype, nullable, primarykey)
Specification of one table column, as stored in `Schemas.toml`.

# Fields
- `name::String`      : Column name.
- `sqltype::String`   : SQL type name, a key of `BASETYPES` (`"INT"`, `"TEXT"`, `"REAL"`).
- `nullable::Bool`    : Whether the column accepts `missing` values.
- `primarykey::Bool`  : Whether the column is part of the primary key.
"""
struct Column
    name::String
    sqltype::String
    nullable::Bool
    primarykey::Bool
end


"""
    TableSchema(tablename, description, columns)
Schema of one table, with the column types already resolved to Julia types.

# Fields
- `tablename::String`                     : Name of the table.
- `description::String`                   : A short description of the table.
- `columns::Vector{Pair{Symbol, Type}}`   : Column names paired with their Julia types
                                            (`Int64`, `Union{String, Missing}`, ...), 
                                            in the order defined in `Schemas.toml`.

Normally built with `schema(table, schemas)` rather than by hand.
"""
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


"""
    appendschema!(table::String,
        columns::Vector{ColumnSpec},
        schemas::Dict{String, Any};
        description::String=""
    ) -> Nothing
Updates the argument `schemas` by adding specifications for a new table.
# Arguments 
- `table::String`              : The name of a new table to be added to `schemas`.
- `columns::Vector{Column}`    : A Vector of `Column`.
- `schemas::Dict{String, Any}` : Dictionary with the specifications of the tables.
- `description::String`        : A short description about the table.
"""
function appendschema!(table::String,
    columns::Vector{Column},
    schemas::Dict{String, Any};
    description::String=""
)
    schemas[table] = Dict(
            "description" => description,
            "columns" => Dict.(columns),
    )
    return nothing 
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


function columnspec(d::Dict)::Vector{Column}
    return Column.(d["columns"])
end


function TableSchema(table::String, d::Dict)
    return TableSchema(
        table,
        d["description"],
        [Symbol(c.name) => parse_type_string(c.sqltype, 
                               c.nullable
                           ) for c in columnspec(d)
        ],
    )
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
function schema(table::String, schemas::Dict{String, Any})::TableSchema
    haskey(schemas, table) || error("Table '$table' not found")
    return TableSchema(table, schemas[table])
end
