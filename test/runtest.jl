using Test, HelloData

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
