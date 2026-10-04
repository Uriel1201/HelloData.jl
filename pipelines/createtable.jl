using HelloData, SQLite, DBInterface, Tables

function main(table::String)
    SQLiteDBS.getconn("HelloData") do conn
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
end


if Base.@isdefined(PROGRAM_FILE) && abspath(PROGRAM_FILE) == abspath(@__FILE__)
    main(ARGS[1])
end
