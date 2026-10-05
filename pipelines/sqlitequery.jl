using HelloData, DBInterface, SQLite

function printresult(conn::SQLite.DB, table::String, queryfile::String)::Nothing
    queryfilepath = joinpath(@__DIR__, "..", "oltp", queryfile)
    if isfile(queryfilepath)
        query = replace(read(queryfilepath, String), "{table}" => table)
        sql = DBInterface.execute(conn, query)
        SQLiteDBS.printsqlite(sql)
    else 
        throw(ArgumentError("queryfile not found: \$queryfilepath"))
    end
    nothing
end # printresult
