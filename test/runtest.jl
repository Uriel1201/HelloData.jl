using Test, DBInterface, SQLite, Tables, HelloData

@testset "loading TOML schemas" begin
    @test HelloData.parse_type_string("INT0") <: Integer
    @test HelloData.parse_type_string("INT1") == Union{Int64,Missing}
    @test HelloData.parse_type_string("TEXT0") == String
    @test HelloData.parse_type_string("TEXT1") == Union{String,Missing}
    @test_throws Regex("Failed to parse type 'invalid_input'") HelloData.parse_type_string(
        "invalid_input",
    )
    @test typeof(HelloData.schema("family")) == Vector{Pair{Symbol,Type}}
    @test map(first, HelloData.schema("family")) == [:name, :gender, :birthday]
    @test map(last, HelloData.schema("family")) == [String, String, String]
    @test_throws ErrorException HelloData.schema("ErrorException")
end #testset
