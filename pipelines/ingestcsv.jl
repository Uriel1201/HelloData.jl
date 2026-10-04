using HelloData, DBInterface, SQLite, CSV, Tables

function loadfile(csvpath::String,
    columnames::Vector{Symbol},
    columntypes::Vector{Type}
)::CSV.Rows
    path = joinpath(datadir(), "csv", csvpath)
    if isfile(path)
        return CSV.Rows(path;
            header=columnames,
            skipto=2,
            types=columntypes
        )
    else
        throw(ArgumentError("csvpath not found: $path"))
    end
end


function ingestfile(data::CSV.Rows,
    table::String,
    columnames::Vector{Symbol};
    batchsize::Int=10000
)
    SQLiteDBS.getconn("HelloData", "rw") do conn
        sql = SQLiteDBS.insertquery(table, columnames)
        stmt = SQLite.Stmt(conn, sql)
        DBInterface.transaction(conn) do
            for chunk in Iterators.partition(data, batchsize)
                DBInterface.executemany(stmt, columntable(chunk))
            end
        end
    end
end


function main(csvpath::String, table::String)
    schema = HelloData.schema(table)
    columnames = map(first, schema)
    columntypes = map(last, schema)
    data = loadfile(csvpath,
        columnames, 
        columntypes
    )
    ingestfile(data, 
        table, 
        columnames; 
        batchsize=2
    )
end


if Base.@isdefined(PROGRAM_FILE) && abspath(PROGRAM_FILE) == abspath(@__FILE__)
    main(ARGS[1], ARGS[2])
end
