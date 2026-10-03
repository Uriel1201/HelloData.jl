using Test, HelloData, SQLite, Tables, DBInterface

@testset "loading TOML schemas" begin
    @test HelloData.parse_type_string("INT0") <: Integer
    @test HelloData.parse_type_string("INT1") == Union{Int64,Missing}
    @test HelloData.parse_type_string("TEXT0") == String
    @test HelloData.parse_type_string("TEXT1") == Union{String,Missing}
    @test_throws Regex("Failed to parse type 'invalid_input'") HelloData.parse_type_string("invalid_input")
    
    z = zip(["name", "gender", "birthday"], ["TEXT0", "TEXT0", "TEXT0"])
    HelloData.appendschema!("family", z; description="Table with information about my family")
    schema = HelloData.schema("family")
    @test typeof(schema) == Vector{Pair{Symbol,Type}}
    @test map(first, schema) == [:name, :gender, :birthday]
    @test map(last, schema) == [String, String, String]
    @test_throws ErrorException HelloData.schema("ErrorException")
end #testset

testset "getting a SQLite connection" begin
    f = function (conn::SQLite.DB)
        result = DBInterface.execute(conn, "select 'Hello World!'")
        c = NamedTuple[]
        for row in result
            push!(c, NamedTuple(row))
        end
        return c
    end
    @test typeof(SQLiteDBS.getconn(f)) == Vector{NamedTuple}
    SQLiteDBS.getconn() do conn
        @test typeof(conn) == SQLite.DB
        stmt = SQLite.Stmt(conn, "SELECT 'HELLO, WORLD!' AS greet")
        result = DBInterface.execute(stmt)
        row = first(result)
        @test row.greet == "HELLO, WORLD!"
    end
end #testset

@testset "displaying results" begin
    @test typeof(SQLiteDBS.insertquery("family", [:name, :gender, :is])) == String
    @test SQLiteDBS.insertquery("family", [:name, :gender, :is]) ==
          "INSERT INTO family (name, gender, is) VALUES (?, ?, ?)"
    SQLiteDBS.getconn() do conn
        SQLite.createtable!(
            conn,
            "family",
            Tables.Schema((:name, :gender, :is), (String, String, String)),
        )
        list = SQLiteDBS.tablenames(conn)
        query = DBInterface.execute(conn, "PRAGMA table_info(family)")
        @test typeof(list) == Vector{String}
        @test list == ["family"]
        @test SQLiteDBS.printsqlite(query, 2) == nothing
        @test_nowarn SQLiteDBS.printsqlite(query, 20)
    end
end #testset

@testset "pushing NamedTuples" begin
    ct = (id = Int[], name = String[])
    row = (id = 1, name = "Margarita")
    result = SQLiteDBS.pushct!(ct, row)
    @test ct.id == [1]
    @test ct.name == ["Margarita"]
    @test result === ct
    SQLiteDBS.pushct!(ct, (id = 2, name = "Uriel"))
    SQLiteDBS.pushct!(ct, (id = 2, name = "Crimson"))
    SQLiteDBS.pushct!(ct, (id = 3, name = "Miles"))
    @test ct.id == [1, 2, 2, 3]
    @test ct.name == ["Margarita", "Uriel", "Crimson", "Miles"]
    c = (id = Int[], amount = Float64[], active = Bool[], name = String[])
    row = (id = 42, amount = 19.5, active = true, name = "Margarita")
    SQLiteDBS.pushct!(c, row)
    @test c.id == [42]
    @test c.amount == [19.5]
    @test c.active == [true]
    @test c.name == ["Margarita"]
    d = (id = Union{Int64,Missing}[], name = String[])
    row = (id = missing, name = "Margarita")
    SQLiteDBS.pushct!(d, row)
    @test isequal(d.id, [missing])
end #testset

@testset "iterating over SQLite.Query" begin
    n = 1000000
    SQLiteDBS.getconn() do conn
        ct = (id = Int64[], sensor = String[])
        for i = 1:n
            SQLiteDBS.pushct!(ct, (id = i, sensor = "$i"))
        end

        SQLite.load!(ct, conn, "test")
        foreach(empty!, ct)

        result = DBInterface.execute(conn, "SELECT * FROM test")
        schema = [:id => Int64, :sensor => Union{String,Missing}]
        nct = NamedTuple{Tuple(first.(schema))}(Tuple(Vector{T}() for (_, T) in schema))

        st = nothing
        batchsize = 400000
        collected = []
        sizes = []

        while true
            st = SQLiteDBS.nextcolumntable!(result, nct; batchsize = batchsize, state = st)
            append!(collected, nct.id)
            push!(sizes, length(nct.id))
            foreach(empty!, values(nct))
            st === nothing && break
        end

        @test isequal(
            SQLiteDBS.pushct!(nct, (id = 7, sensor = missing)),
            (id = Int64[7], sensor = Union{String,Missing}[missing]),
        )
        @test collected == collect(1:n)
        @test sizes == [400000, 400000, 200000]
        @test SQLiteDBS.nextcolumntable!(
            result,
            nct;
            batchsize = batchsize,
            state = nothing,
        ) === nothing

        SQLite.createtable!(conn, "empty_t", Tables.Schema((:id,), (Int,)))
        result = DBInterface.execute(conn, "SELECT * FROM empty_t")
        @test SQLiteDBS.nextcolumntable!(result, ct; state = nothing) === nothing
    end
end #testset
