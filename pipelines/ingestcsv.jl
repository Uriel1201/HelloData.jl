using HelloData, DBInterface, SQLite, CSV, Tables

function loadfile(csvfile::String,
    columnames::Vector{Symbol},
    columntypes::Vector{Type}
)::CSV.Rows
    csvpath = joinpath(datadir(), "csv", csvfile)
    if isfile(csvpath)
        return CSV.Rows(csvpath;
            header=columnames,
            skipto=2,
            types=columntypes
        )
    else
        throw(ArgumentError("csvpath not found: $csvpath"))
    end
end


function main(csvfile::String, 
    table::String, 
    databasename::String; 
    batchsize::Int=10000
)
    schema = HelloData.schema(table)
    columnames = map(first, schema)
    columntypes = map(last, schema)
    dbpath = joinpath(datadir(), "$databasename.sqlite")
    if isfile(dbpath)
        data = loadfile(csvfile,
            columnames, 
            columntypes
        )
        SQLiteDBS.getconn(dbpath, "rw") do conn
            sql = SQLiteDBS.insertquery(table, columnames)
            stmt = SQLite.Stmt(conn, sql)
            DBInterface.transaction(conn) do
                for chunk in Iterators.partition(data, batchsize)
                    DBInterface.executemany(stmt, columntable(chunk))
                end
            end
        end
    else
        throw(ArgumentError("database path not found: $dbpath"))
    end
end


if Base.@isdefined(PROGRAM_FILE) && abspath(PROGRAM_FILE) == abspath(@__FILE__)
    main(ARGS[1], 
        ARGS[2], 
        ARGS[3]; 
        batchsize=parse(Int, ARGS[4])
    )
end
