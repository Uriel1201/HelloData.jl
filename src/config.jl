module Config
#=
using DotEnv
join_path = joinpath(@__DIR__, "..", "env")
DotEnv.load!(join_path)
=#
const URI_POSTGRESQL = ENV["URI_POSTGRESQL"]
const URI_MYSQL = ENV["URI_MYSQL"]
const ODB_DSN = ENV["ODB_DSN"]
const ODB_USER = ENV["ODB_USER"]
const ODB_PASSWORD = ENV["ODB_PASSWORD"]

end #module Config
