module SQLiteDBS

using SQLite, Tables, DBInterface
import ..datadir


"""
    getconn(f::Function, 
        database_name::String = ":memory:", 
        mode::String = "rwc"
    )
Executes the function `f` with an active SQLite connection and ensures the connection
is safely closed afterwards, even if an exception occurs.

# Arguments
- `f::Function`.         : Function receiving the argument (`db::SQLite.DB`).
- `databasename::String` : The name of an archive.sqlite.
- `mode::String`.        : The mode query parameter that determines how the new database is opened.

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
        path = joinpath(datadir(), "$databasename.sqlite")
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
    registersqlite!(conn::SQLite.DB, 
        table::String; 
        description::String=""
    ) -> Nothing 
Updates the Schemas.toml file by registering a table schema from a SQLite database.

# Arguments 
- `conn::SQLite.DB`     : The current SQLite connection.
- `table::String`       : The name of a SQLite table.
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
- n::Int              : The first n rows of a SQLite.Query result.

# Example 
```julia
julia> SQLiteDBS.getconn() do conn
           SQLite.createtable!(conn, 
               "example", 
               Tables.Schema((:id, :name), 
                   (Int, String)
               )
           )
           query = DBInterface.execute(conn, "PRAGMA table_info(example)")
           SQLiteDBS.printsqlite(query)
       end

Database SQLite.DB("file::memory:?cache=private") connected
(cid = 0, name = "id", type = "INT", notnull = 1, dflt_value = missing, pk = 0)
(cid = 1, name = "name", type = "TEXT", notnull = 1, dflt_value = missing, pk = 0)
```
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
Append a new `NamedTuple` `nt` to `ct`, a `NamedTuple` of vectors with the same keys as `nt`.
Each value of `nt` is added to the corresponding vector of `ct` using `push!`.

# Return
- Returns the modified `ct`.

#Example
```julia
julia> ct = NamedTuple{(:id, :name)}((Vector{Int64}(), Vector{String}()))
julia> nt = (id = 1, name = "Margarita")
julia> SQLiteDBS.pushct!(ct, nt)

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


"""
    nextcolumntable!(result::SQLite.Query, 
        ct::NamedTuple{names, <:Tuple{Vararg{<:Vector}}};
        batchsize::Int64=10000, 
        state=nothing
    )
Iterates over an `SQLite.Query`, returning a chunk of the results as a column table on each 
iteration, reducing the overhead of iterating over and converting the data 
into a columntable in separate steps.

# Arguments
- result::SQLite.Query : A data structure in `SQLite.jl` that represents 
                         a lazy query or a row-by-row iterator over the query results.
- ct::NamedTuple       : A `NamedTuple` of vectors serving as recipient to aggregate data from `result`
- batchsize::Int64     : The size of the batch returned.
- state=nothing        : The state of the current iteration, defaults to nothing for the first iteration 

# Return 
- `nextstate::Integer` or `nothing`.

# Example
```julia
julia>  st = nothing
        batchsize = 400000
        collected = []
        sizes = []

        while true
            st = SQLiteDBS.nextcolumntable!(result, 
                nct; 
                batchsize = batchsize, 
                state = st
            )
            append!(collected, nct.id)
            push!(sizes, length(nct.id))
            foreach(empty!, values(nct))
            st === nothing && break
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
