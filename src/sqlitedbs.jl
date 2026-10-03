module SQLiteDBS

using SQLite, Tables, DBInterface
const DATADIR = get(ENV, "DATA_DIR", nothing)

"""
    getconn(f::Function, database_name::String = ":memory:", mode::String = "rwc")
Executes the function `f` with an active SQLite connection and ensures the connection
is safely closed afterwards, even if an exception occurs.

# Arguments
- `f::Function`: Function receiving the argument (`db::SQLite.DB`).
- `databasename::String`: The name of an archive.sqlite.
- `mode::String`: The mode query parameter that determines how the new database is opened.

# Return
- The result of executing `f(db)`.

# Example
```julia
julia> f = function(conn)
           result = DBInterface.execute(conn, "select 'Hello World!'")
           for row in result
               println("row: \$(Tuple(row))")
           end
       end

julia> getconn(f)
```
"""
function getconn(f::Function, 
    databasename::String = ":memory:",
    mode::String = "rwc"
)
    if databasename == ":memory:"
        uri = "file::memory:?cache=private"
    else
        path = joinpath(DATADIR, "$databasename.sqlite")
        uri = "file:$path?mode=$mode"
    end
    db = nothing 
    try
        db = SQLite.DB(uri)
        println("Database $db connected")
        return f(db)
    finally
        db === nothing || SQLite.close(db)
    end
end #getconn


"""
    registersqlite!(conn::SQLite.DB, table::String; description::String="") -> Nothing 
Updates the Schemas.toml file by registering a table schema from a SQLite database.
# Arguments 
- `conn::SQLite.DB` : The current SQLite connection.
- `table::String` : The name of a SQLite table.
- `description::String` : A short description about the table.
# Example
```julia
julia> SQLiteDBS.getconn("mydatabase", "ro") do conn
           SQLiteDBS.registersqlite!(conn, 
               "mytable"; 
               description="A short description"
           )
       end
```
"""
function registersqlite!(conn::SQLite.DB, 
    table::String; 
    description::String=""
)::Nothing
    query = DBInterface.execute(conn, "PRAGMA table_info('$table')")
    ct = columntable(query)
    stypes = map((x, y) -> string(x,y), ct.type, ct.notnull)
    z = zip(ct.name, stypes)
    appendschema!(table, z; description)
    nothing 
end


"""
    insertquery(table::String, column_names::String) -> String
Returns a string representing an `INSERT` query, given a table name 
and a collection of symbols.
# Example
```julia
julia> SQLiteDBS.insertquery("users", [:id, :name])
"INSERT INTO users (id, name) VALUES (?, ?)"
```
"""
function insertquery(table::String, column_names::Vector{Symbol})::String
    num_of_columns = length(column_names)
    columns = join(column_names, ", ")
    values = join(fill("?", num_of_columns), ", ")
    return "INSERT INTO $table ($columns) VALUES ($values)"
end #insertquery


"""
    tablenames(conn::SQLite.DB) -> Vector{String}
Returns a list of the table names available to query in the `SQLite.DB` database.
# Arguments
- `conn::SQLite.DB` : The current SQLite connection.
# Example 
```julia
julia> SQLiteDBS.getconn() do conn
           SQLiteDBS.tablenames(conn)
       end
[]
```
"""
function tablenames(conn::SQLite.DB)::Vector{String}
    return [t.name for t in SQLite.tables(conn)]
end #tablenames


"""
    printsqlite(query::SQLite.Query, n::Int64=50) -> Nothing 
Shows a collection of NamedTuple's with exactly the first n rows of a query result

# Arguments
- query::SQLite.Query : The result of requesting data from a Sqlite table
- n::Int64 : The first n rows of a SQLite.Query result 
"""
function printsqlite(query::SQLite.Query, n::Int=50)::Nothing 
    n > 0 || throw(ArgumentError("n must be positive"))
    table = rowtable(Iterators.take(query, n))
    for row in table
        println(NamedTuple(row))
    end
    nothing 
end #printsqlite


"""
    function pushct!(ct::NamedTuple{names, <:Tuple{Vararg{<:Vector}}},
        nt::NamedTuple{names}
    ) where{names}
"""
function pushct!(ct::NamedTuple{names, <:Tuple{Vararg{<:Vector}}},
    nt::NamedTuple{names}
) where{names}
    for k in keys(ct)
        push!(ct[k], nt[k])
    end
    return ct
end #pushct!


"""
    nextcolumntable!(result::SQLite.Query, batchsize::Int64=10000, state=nothing)
Iterates over an SQLite.Query, returning a chunk of the results as a column table on each 
iteration, reducing the overhead of iterating over and converting the data into a columntable in separate steps.
# Arguments
- result::SQLite.Query : A data structure in SQLite.jl that represents 
  a lazy query or a row-by-row iterator over the query results.
- batchsize::Int64 : The size of the batch returned.
- state=nothing : The state of the current iteration, defaults to nothing for the first iteration 
# Return 
- A Tuple (batch::NamedTuple, nextstate) or nothing.
# Example
```julia
julia> SQLiteDBS.get_conn() do conn
           # Populating the test table with data
           # ...........
           result = DBInterface.execute(conn, "SELECT * FROM test")
           state = nothing
           open(Arrow.Writer, file) do writer
               while true
                   res = SQLiteDBS.nextcolumntable!(result, 1000000, state) # <- next_columntable!
                   res === nothing && break
                   c, state = res
                   Arrow.write(writer, c)
               end
           end
       end
``` 
"""
function nextcolumntable!(
    result::SQLite.Query,
    ct::NamedTuple{names, <:Tuple{Vararg{<:Vector}}};
    batchsize::Int64=10000,
    state=nothing
)::Union{Integer, Nothing} where {names}
    next = state === nothing ? iterate(result) : iterate(result, state)
    next === nothing && return nothing
    row, st = next
    pushct!(ct, NamedTuple(row))
    i = 1
    exhausted = false
    while i < batchsize
        next = iterate(result, st)
        if next === nothing
            exhausted = true
            break
        end
        row, st = next
        pushct!(ct, NamedTuple(row))
        i += 1
    end
    return exhausted ? nothing : st
end #nextcolumntable!

end # SQLiteDBS
