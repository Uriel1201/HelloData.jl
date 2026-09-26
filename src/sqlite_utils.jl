module SQLiteDBS

using SQLite, Arrow, CSV, Tables, DBInterface

"""
    get_conn(f::Function, database_name::String = ":memory:", mode::String = "rwc")
Executes the function `f` with an active SQLite connection and ensures the connection
is safely closed afterwards, even if an exception occurs.

# Arguments
- `f::Function`: Function receiving the argument (`db::SQLite.DB`).
- `database_name::String`: The name of an archive.sqlite.
- `mode::String`: The mode query parameter that determines how the new database is opened

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

julia> get_conn(f)
```
"""
function get_conn(f::Function, database_name::String = ":memory:", mode::String = "rwc")
    if database_name == ":memory:"
        uri = "file::memory:?cache=private"
        db = SQLite.DB()
    else
        path = joinpath(@__DIR__, "$database_name.sqlite")
        uri = "file:$path?mode=$mode"
        db = SQLite.DB(uri)
    end
    println("Database $db connected")
    try
        return f(db)
    finally
        SQLite.close(db)
    end
end #get_conn


"""
    insert_query(table::String, column_names::String) -> String
Returns a string representing an `INSERT` query, given a table name and a collection of symbols
# Examples
```julia
julia> insert_query("users", [:id, :name])
"INSERT INTO users (id, name) VALUES (?, ?)"
```
"""
function insert_query(table::String, column_names::Vector{Symbol})::String
    num_of_columns = length(column_names)
    columns = join(column_names, ", ")
    values = join(fill("?", num_of_columns), ", ")
    return "INSERT INTO $table ($columns) VALUES ($values)"
end #insert_query


"""
    table_names(conn::SQLite.DB) -> Vector{String}
Returns a list of the table names available to query in the `SQLite.DB` database.
"""
function table_names(conn::SQLite.DB)::Vector{String}
    return [t.name for t in SQLite.tables(conn)]
end #table_names


"""
    print_sql(query::SQLite.Query, n::Int64=50) -> Nothing 
Shows a collection of NamedTuple's with exactly the first n rows of a query result

# Arguments
- query::SQLite.Query : The result of requesting data from a Sqlite table
- n::Int64 : The first n rows of a SQLite.Query result 
"""
function print_sqlite(query::SQLite.Query, n::Int64=50)::Nothing 
    table = rowtable(Iterators.take(query, n))
    for row in table
        println(row)
    end
end #print_sqlite


"""
    create_arrow(io::IO, result::SQLite.Query, batch_size::Int64=10000) -> Nothing
"""
function create_arrow(io::IO, result::SQLite.Query, batch_size::Int64=10000)::Nothing
    values = NamedTuple[]
    open(Arrow.Writer, io) do writer
        for row in result
            push!(values, NamedTuple(row))
            if length(values) == batch_size
                Arrow.write(writer, values)
                values = NamedTuple[]
            end
        end
        if !isempty(values)
            Arrow.write(writer, values)
        end
    end
    nothing
end #create_arrow


"""
    ingest_csv(stmt::SQLite.Stmt, data::CSV.Rows) -> Nothing
"""
function ingest_csv(stmt::SQLite.Stmt, data::CSV.Rows)::Nothing
    try 
        for batch in Iterators.partition(data, 2000)
            column_table = columntable(batch)
            DBInterface.executemany(stmt, column_table)
        end
    catch e
        @error "unable to execute ingestion"
        rethrow(e)
    end
    nothing
end #ingest_cav

end #module SQLiteDBS
