using HelloData, SQLite, DBInterface, Tables

datadir() = get(ENV, "DATA_DIR", nothing)

function sqlitetable(conn::SQLite.DB, table::String)
    schema = HelloData.schema(table)
    columnames = map(first, schema)
    columntypes = map(last, schema)
    SQLite.createtable!(conn, 
        table, 
        Tables.Schema(columnames, 
            columntypes
        )
    )
end


function main(table::String)
    dbpath = joinpath(datadir(), "HelloData.sqlite")
    if isfile(dbpath)
        mode="rw"
    else
        mode="rwc"
    end
    SQLiteDBS.getconn(dbpath; mode=mode) do conn
        sqlitetable(conn, table)
    end
end


if Base.@isdefined(PROGRAM_FILE) && abspath(PROGRAM_FILE) == abspath(@__FILE__)
    main(ARGS[1])
end
