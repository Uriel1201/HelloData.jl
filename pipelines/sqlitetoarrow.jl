

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
        toarrow(sql,
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
