using HelloData, SQLite, DBInterface, Tables

function sqlitetable(table::String, databasename::String)
    dbpath = joinpath(datadir(), "$databasename.sqlite")
    schema = HelloData.schema(table)
    columnames = map(first, schema)
    columntypes = map(last, schema)
    if isfile(dbpath)
        SQLiteDBS.getconn(dbpath; mode="rw") do conn
            SQLite.createtable!(conn, 
                table, 
                Tables.Schema(columnames, 
                columntypes
                )
            )
        end
    else
        SQLiteDBS.getconn(dbpath) do conn
            SQLite.createtable!(conn, 
                table, 
                Tables.Schema(columnames, 
                columntypes
                )
            )
        end
    end
end

function main(table::String)
    sqlitetable(table, "HelloData")
end


if Base.@isdefined(PROGRAM_FILE) && abspath(PROGRAM_FILE) == abspath(@__FILE__)
    main(ARGS[1])
end
