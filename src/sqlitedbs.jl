"""
    getconn(f::Function, 
        databasepath::String = ":memory:";
        mode::String = "rwc"
    )
Executes the function `f` with an active SQLite connection and ensures the connection
is safely closed afterwards, even if an exception occurs.

# Arguments
- `f::Function`          : Function receiving the argument (`db::SQLite.DB`).
- `databasepath::String` : The directory of an archive.sqlite.
- `mode::String`         : The mode query parameter that determines how the new database is opened.

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
    databasepath::String = ":memory:";
    mode::String = "rwc"
)
    if databasepath == ":memory:"
        uri = "file::memory:?cache=private"
    else
        uri = "file:$databasepath?mode=$mode"
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
    registertable!(schemas::Dict{String, Any},
        conn::SQLite.DB,
        table::String;
        description::String=""
    ) -> Nothing

Reads the structure of a SQLite table and adds its specification to `schemas`,
modifying it in place. Does not write to disk.

# Arguments
- `schemas::Dict{String, Any}` : Dictionary with the specifications of the tables. Modified in place.
- `conn::SQLite.DB`            : The current SQLite connection.
- `table::String`              : The name of a SQLite table.
- `description::String`        : A short description about the table.

# Example
```julia
julia> schemas = TOML.parsefile(tomlpath)

julia> getconn("mydatabase"; mode="ro") do conn
           registertable!(schemas, conn, "mytable";
               description = "A short description")
       end
```
"""
function registertable!(schemas::Dict{String, Any},
    conn::SQLite.DB, 
    table::String; 
    description::String=""
)::Nothing
    ct = columntable(DBInterface.execute(conn, "PRAGMA table_info('$table')"))
    columns = Column.(ct.name, ct.type, ct.notnull.==0, ct.pk.>0)
    appendschema!(table, columns, schemas; description)
    return nothing
end


"""
    insertquery(table::String, columnames::Vector{Symbol}) -> String
Returns a string representing an `INSERT` query, given a table name 
and a collection of symbols.

# Example
```julia
julia> insertquery(conn, "users", [:id, :name])

"INSERT INTO users (id, name) VALUES (?, ?)"
```
"""
function insertquery(conn::SQLite.DB, 
    table::String, 
    columnames::Vector{Symbol}
)::String
    num_of_columns = length(columnames)
    columns = join(columnames, ", ")
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
julia> getconn() do conn
           tablenames(conn)
       end
[]
```
"""
function tablenames(conn::SQLite.DB)::Vector{String}
    return [t.name for t in SQLite.tables(conn)]
end #tablenames


"""
    printquery(query::SQLite.Query, n::Int64=50) -> Nothing 
Shows a collection of NamedTuple's with exactly the first n rows of a query result

# Arguments
- `query::SQLite.Query` : The result of requesting data from a Sqlite table
- `n::Int`              : The first n rows of a SQLite.Query result.

# Example 
```julia
julia> getconn() do conn
           SQLite.createtable!(conn, 
               "example", 
               Tables.Schema((:id, :name), 
                   (Int, String)
               )
           )
           query = DBInterface.execute(conn, "PRAGMA table_info(example)")
           printquery(query)
       end

Database SQLite.DB("file::memory:?cache=private") connected
(cid = 0, name = "id", type = "INT", notnull = 1, dflt_value = missing, pk = 0)
(cid = 1, name = "name", type = "TEXT", notnull = 1, dflt_value = missing, pk = 0)
```
"""
function printquery(query::SQLite.Query, n::Int=50)::Nothing 
    n > 0 || throw(ArgumentError("n must be positive"))
    table = rowtable(Iterators.take(query, n))
    for row in table
        println(NamedTuple(row))
    end
    nothing 
end #printquery


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
- `result::SQLite.Query` : A data structure in `SQLite.jl` that represents 
                           a lazy query or a row-by-row iterator over the query results.
- `ct::NamedTuple`       : A `NamedTuple` of vectors serving as recipient to aggregate data from `result`
- `batchsize::Int64`     : The size of the batch returned.
- `state=nothing`        : The state of the current iteration, defaults to nothing for the first iteration 

# Return 
- `nextstate::Integer` or `nothing`.

# Example
```julia
julia>  st = nothing
        batchsize = 400000
        collected = []
        sizes = []

        while true
            st = nextcolumntable!(result, 
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


"""
    function ingestcsv!(
        table::String,
        columnames::Vector{Symbol},
        data::CSV.Rows;
        batchsize::Int=10000
    ) -> Nothing 
Ingests a `CSV.Rows` object into a table in the current SQLite connection. 
The column names and types must match those of the target table.

# Arguments 
- `conn::SQLite.DB`            : The current SQLite connection.
- `table::String`              : The table that will ingest the data.
- `columnames::Vector{Symbol}` : The vector that contains the columnnames of `table`.
- `data::CSV.Rows`             : The CSV.Rows object that contains the data. 
                                 This object only provides row access via iteration.
- `batchsize::Int=10000`       : The size of the chunk that will be ingested by each iteration 

# Return 
- `nothing`
"""
function ingestcsv!(conn::SQLite.DB, 
    table::String,
    columnames::Vector{Symbol},
    data::CSV.Rows;
    batchsize::Int=10000
)::Nothing 
    stmt = SQLite.Stmt(conn, 
        insertquery(conn,
            table, 
            columnames
        )
    )
    DBInterface.transaction(conn) do
        for chunk in Iterators.partition(data, batchsize)
            DBInterface.executemany(stmt, columntable(chunk))
        end
    end
    nothing 
end #ingestcsv


"""
    toarrow(query::SQLite.Query, 
        columns::Vector{Pair{Symbol, Type}},
        io::IO; 
        batchsize::Int=10000
    ) -> Nothing

Converts the contents of a SQLite.Query object to Arrow format 
and writes them to an IO object.

# Arguments 
- `query::SQLite.Query`                 : The result of requesting data from a Sqlite table.
- `columns::Vector{Pair{Symbol, Type}}` : A vector of symbols and types that represents 
                                          the schema of the table.
- `io::IO`                              : An object that implements the IO interface 
                                          and can be used to read or write data.
- `batchsize::Int=10000`                : The size of a batch that will be write by each iteration.

# Example 
```julia
julia> open(filepath, "w") do io
           HelloData.toarrow(sql,
               columns,
               io;
               batchsize=batchsize
           )
       end
```
"""
function toarrow(query::SQLite.Query,
    columns::Vector{Pair{Symbol, Type}},
    io::IO;
    batchsize::Int=10000
)::Nothing
    names = Tuple(first.(columns))
    open(Arrow.Writer, io, closeio=false) do writer
        st = nothing
        while true
            ct = NamedTuple{names}(Tuple(Vector{T}() for (_, T) in columns))
            st = nextcolumntable!(query,
                ct;
                batchsize = batchsize,
                state = st
            )
            Arrow.write(writer, ct)
            st === nothing && break
        end
    end
end # toarrow
