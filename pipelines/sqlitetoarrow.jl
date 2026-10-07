using HelloData, SQLite, DBInterface, Arrow

datadir() = get(ENV, "DATA_DIR", nothing)


function returntable(conn::SQLite.DB,
    table::String
)::SQLite.Query
    sqlpath = joinpath(@__DIR__, "..", "oltp", "table.sql")
    sql = replace(read(sqlpath, String), "{table}" => table)
    return DBInterface.execute(conn, sql)
end


function sqlitetoarrow(conn::SQLite.DB,
    table::String;
    batchsize::Int=10000
)
    schema = HelloData.schema(table)
    sql = returntable(conn, table)
    filepath = joinpath(datadir(), "arrow", "$table.arrow")
    open(filepath, "w") do io
        HelloData.toarrow(sql,
            schema,
            io;
            batchsize=batchsize
        )
    end
end


function main(table::String)
    hello = joinpath(datadir(), "HelloData.sqlite")
    SQLiteDBS.getconn(hello; mode="ro") do conn
        sqlitetoarrow(conn, table, batchsize=5)
    end
end


if Base.@isdefined(PROGRAM_FILE) && abspath(PROGRAM_FILE) == abspath(@__FILE__)
    main(ARGS[1])
end


