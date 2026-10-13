using Test, HelloData, SQLite, Tables, DBInterface, CSV


@testset "schemas.jl" begin
    @test HelloData.parse_type_string("INT", false)  == Int64
    @test HelloData.parse_type_string("INT", true)   == Union{Int64, Missing}
    @test HelloData.parse_type_string("TEXT", false) == String
    @test HelloData.parse_type_string("TEXT", true)  == Union{String,Missing}
    @test HelloData.parse_type_string("REAL", true)  == Union{Float64, Missing}
    @test HelloData.parse_type_string("REAL", false) == Float64
    @test_throws ErrorException("Type unknown: invalid_type") HelloData.parse_type_string("invalid_type", true)

    schemas = Dict{String, Any}()
    columns = [HelloData.Column("name", 
                   "TEXT", 
                   false, 
                   true
               ), 
               HelloData.Column("gender", 
                   "TEXT", 
                   false, 
                   false
               )
              ]
    HelloData.appendschema!("family", 
        columns, 
        schemas; 
        description="Table with information about my family"
    )
    @test haskey(schemas, "family")
    @test schemas["family"]["description"] == "Table with information about my family"
    @test schemas["family"]["columns"] isa Vector{<:AbstractDict}
    @test HelloData.columnspec(schemas["family"]) isa Vector{HelloData.Column}
    @test_throws KeyError HelloData.columnspec(Dict("description" => 
                                                    "Table with information about my family"
                                               )
                          )
    firstcolumn = HelloData.columnspec(schemas["family"])[1]
    @test firstcolumn.name       == "name"
    @test firstcolumn.sqltype    == "TEXT"
    @test firstcolumn.nullable   == false
    @test firstcolumn.primarykey == true

    familyschema = HelloData.schema("family", schemas)
    @test familyschema isa HelloData.TableSchema
    @test familyschema.columns isa Vector{Pair{Symbol, Type}}
end #testset


@testset "utils.jl" begin 
    ct = (id = Int[], name = String[])
    nt = (id = 1, name = "Margarita")
    result = HelloData.pushct!(ct, nt)
    @test ct.id == [1]
    @test ct.name == ["Margarita"]
    @test result === ct
    HelloData.pushct!(ct, (id = 2, name = "Uriel"))
    HelloData.pushct!(ct, (id = 2, name = "Crimson"))
    HelloData.pushct!(ct, (id = 3, name = "Miles"))
    @test ct.id == [1, 2, 2, 3]
    @test ct.name == ["Margarita", "Uriel", "Crimson", "Miles"]
    nct = (id = Int[], amount = Float64[], active = Bool[], name = String[])
    nnt = (id = 42, amount = 19.5, active = true, name = "Margarita")
    HelloData.pushct!(nct, nnt)
    @test nct.id     == [42]
    @test nct.amount == [19.5]
    @test nct.active == [true]
    @test nct.name   == ["Margarita"]
    d = HelloData.pushct!((id   = Union{Int64,Missing}[], 
                           name = String[]), 
            (id   = missing, 
             name = "Margarita")
        )
    @test isequal(d.id, [missing])
end


@testset "sqlitedbs.jl" begin
    f = function (conn::SQLite.DB)
        result = DBInterface.execute(conn, "select 'Hello World!'")
        c = NamedTuple[]
        for row in result
            push!(c, NamedTuple(row))
        end
        return c
    end
    @test typeof(HelloData.getconn(f)) == Vector{NamedTuple}
    HelloData.getconn() do conn
        @test typeof(conn) == SQLite.DB
        stmt = SQLite.Stmt(conn, "SELECT 'HELLO, WORLD!' AS greet")
        result = DBInterface.execute(stmt)
        row = first(result)
        @test row.greet == "HELLO, WORLD!"
        @test typeof(HelloData.insertquery(conn, "family", [:name, :gender, :is])) == String
        @test HelloData.insertquery(conn, "family", [:name, :gender, :is]) ==
          "INSERT INTO family (name, gender, is) VALUES (?, ?, ?)"
        SQLite.createtable!(
            conn,
            "family",
            Tables.Schema((:name, :gender, :is), (String, String, String)),
        )
        query = DBInterface.execute(conn, "PRAGMA table_info(family)")
        @test typeof(HelloData.tablenames(conn)) == Vector{String}
        @test HelloData.tablenames(conn) == ["family"]
        @test HelloData.printquery(query, 2) == nothing
        @test_nowarn HelloData.printquery(query, 20)
  
        n = 1000000
        ct = (id = Int64[], sensor = String[])
        for i = 1:n
            HelloData.pushct!(ct, (id = i, sensor = "$i"))
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
            st = HelloData.nextcolumntable!(result, 
                nct; 
                batchsize = batchsize, 
                state = st
            )
            append!(collected, nct.id)
            push!(sizes, length(nct.id))
            foreach(empty!, values(nct))
            st === nothing && break
        end

        @test isequal(
            HelloData.pushct!(nct, (id = 7, sensor = missing)),
            (id = Int64[7], sensor = Union{String,Missing}[missing]),
        )
        @test collected == collect(1:n)
        @test sizes == [400000, 400000, 200000]
        @test HelloData.nextcolumntable!(
                  result,
                  nct;
                  batchsize = batchsize,
                  state = nothing,
              ) === nothing

        SQLite.createtable!(conn, "empty_t", Tables.Schema((:id,), (Int,)))
        result = DBInterface.execute(conn, "SELECT * FROM empty_t")
        @test HelloData.nextcolumntable!(result, ct; state = nothing) === nothing
    end

    schemas = Dict{String, Any}()
    columns = [HelloData.Column("name", 
                   "TEXT", 
                   true, 
                   true
               ), 
               HelloData.Column("gender", 
                   "TEXT", 
                   true, 
                   false
               ),
               HelloData.Column("birthday", 
                   "TEXT", 
                   true, 
                   false
               )
              ]
    
    HelloData.appendschema!("family", 
        columns, 
        schemas; 
        description="Table with information about my family"
    )
    family      = HelloData.schema("family", schemas)
    columnames  = map(first, family.columns)
    columntypes = map(last, family.columns)
    csv = """
    nombre,genero,cumple
    Margarita,dog,01-feb-2018
    """
    rows = CSV.Rows(IOBuffer(csv);
               header=columnames,
               types=columntypes,
               skipto=2
           )
    HelloData.getconn() do conn
        SQLite.createtable!(
            conn,
            "family",
            Tables.Schema(columnames, columntypes)
        )
        HelloData.ingestcsv!(
            conn,
            "family",
            columnames,
            rows
        )
        result = DBInterface.execute(conn, "SELECT * FROM family")
        db_row = NamedTuple(first(result))
        @test db_row == (name = "Margarita", gender = "dog", birthday = "01-feb-2018")
    end
end #testset
