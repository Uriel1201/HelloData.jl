module HelloData

using TOML, Arrow, SQLite, Tables, DBInterface, CSV


function getconn end
function registertable! end
function insertquery end
function tablenames end
function printquery end
function ingestcsv! end
function toarrow end

include("utils.jl")

include("schemas.jl")

include("sqlitedbs.jl")

println("[Julia] Hello, Data!, We are ready")

end # module HelloData
