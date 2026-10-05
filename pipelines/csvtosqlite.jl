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


function csvtosqlite(conn::SQLite.DB, 
    table::String, 
    csvfile::String; 
    batchsize::Int=10000
)
    schema = HelloData.schema(table)
    columnames = map(first, schema)
    columntypes = map(last, schemas)
    data = loadfile(csvfile, columnames, columntypes)
    HelloData.ingestcsv(conn, 
        table, 
        columnames, 
        data; 
        batchsize=batchsize 
    )
end


function main(table::String, csvfile::String)
    dbpath = joinpath(datadir(), "HelloData.sqlite")
    SQLiteDBS.getconn(dbpath; mode="rw") do conn
        csvtosqlite(conn, table, csvfile)  
    end
end


if Base.@isdefined(PROGRAM_FILE) && abspath(PROGRAM_FILE) == abspath(@__FILE__)
    main(ARGS[1], ARGS[2])
end
