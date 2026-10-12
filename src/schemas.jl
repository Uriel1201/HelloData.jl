using TOML

const BASETYPES = Dict{String, Type}(
    "INT"  => Int64,
    "TEXT" => String,
    "REAL" => Float64,
)


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


"""
    Column(d::Dict) -> Column

Builds a `Column` from a dictionary, as read from the `toml` file.

# Arguments
- `d::Dict` : Dictionary with the keys `"name"`, `"sqltype"`, `"nullable"` and `"primarykey"`.

Throws a `KeyError` if any of the keys is missing.
"""
function Column(d::Dict)
    return Column(
        d["name"],
        d["sqltype"],
        d["nullable"],
        d["primarykey"],
    )
end


"""
    Dict(c::Column) -> Dict{String, Any}

Converts a `Column` into the dictionary used to store it in the `toml` file.
Each of these dictionaries is one element of the vector stored under the
key `"columns"` of a table. This is the inverse of `Column(d::Dict)`: 
both must use the same keys.

# Keys
- `"name"`       : Column name.
- `"sqltype"`    : SQL type name, a key of `BASETYPES`.
- `"nullable"`   : Whether the column accepts `missing` values.
- `"primarykey"` : Whether the column is part of the primary key.

Every value is a `String` or a `Bool`, so the result can be written with `TOML.print`.

# Example
Into a toml file.
[family] 
columns = [{ name = "id", sqltype = "INT", nullable = false, primarykey = true }]
"""
function Base.Dict(c::Column)
    return Dict{String, Any}(
        "name"        => c.name,
        "sqltype"     => c.sqltype,
        "nullable"    => c.nullable,
        "primarykey"  => c.primarykey,
    )
end


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
    ) -> Type

Converts a String into a Julia Type code.
The content of the string is predetermined by BASETYPES

# Arguments
- `base::String`   : A String containing the Julia `Type` to be parsed.
- `nullable::Bool` : Specifies wether a column accepts `missing` values.

# Return 
- the Julia Type parsed from the String 
"""
function parse_type_string(base::String, 
    nullable::Bool
)::Type
    haskey(BASETYPES, base) || error("Type unknown: $base")
    T = BASETYPES[base]
    return nullable ? Union{T, Missing} : T
end


"""
    columnspec(schemastable::Dict) -> Vector{Column}

Converts the columns of one table specification into a `Vector{Column}`.

# Arguments
- `schemastable::Dict` : The specification of a single table, i.e. the value
                         stored under the key `table` in `schemas` (`schemas[table]`). 
                         It must contain the key `"columns"`, 
                         a vector of dictionaries, one per column.

Throws a `KeyError` if `"columns"` is missing, or if any column lacks one of
its required keys (see `Column(d::Dict)`).
"""
function columnspec(schemastable::Dict)::Vector{Column}
    return Column.(schemastable["columns"])
end


"""
"""
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
    schema(table::String) -> TableSchema

Returns the TableSchema of a table stored in `Dict{String, Any}`.

# Arguments
- `table::String`: A table `key` difined in `Dict{String, Any}`.

# Return 
- A vector of pairs containing the table's metadata
"""
function schema(table::String, schemas::Dict{String, Any})::TableSchema
    haskey(schemas, table) || error("Table '$table' not found")
    return TableSchema(table, schemas[table])
end
