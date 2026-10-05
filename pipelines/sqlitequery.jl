using HelloData, DBInterface, SQLite

function sqlitequery(conn::SQLite.DB, table::String, queryfile::String)::Nothing
    queryfilepath = joinpath(@__DIR__, "..", "oltp", queryfile)
    if isfile(queryfilepath)
        query = replace(read(queryfilepath, String), "{table}" => table)
        sql = DBInterface.execute(conn, query)
        SQLiteDBS.printsqlite(sql)
    else
        throw(ArgumentError("queryfile not found: $queryfilepath"))
    end
    nothing
end # printresult


function main(table::String, queryfile::String)
    hello = joinpath(datadir(), "HelloData.sqlite")
    SQLiteDBS.getconn(hello; mode="rw") do conn
        sqlitequery(conn, table, queryfile)
    end
end


if Base.@isdefined(PROGRAM_FILE) && abspath(PROGRAM_FILE) == abspath(@__FILE__)
    main(ARGS[1], ARGS[2])
end
