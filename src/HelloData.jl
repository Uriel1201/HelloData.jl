module HelloData

using TOML

include("schemas.jl")

export SQLiteDBS, datadir

include("sqlitedbs.jl")

using .SQLiteDBS, Arrow, SQLite

datadir() = get(ENV, "DATA_DIR", nothing)

function toarrow end

"""
    toarrow(query::SQLite.Query, 
        schema::Vector{Pair{Symbol, Type}},
        io::IO; 
        batchsize::Int64=10000
    ) -> Nothing
"""
function toarrow(query::SQLite.Query,
    schema::Vector{Pair{Symbol, Type}},
    io::IO;
    batchsize::Int64=10000
)::Nothing
    ct = NamedTuple{Tuple(first.(schema))}(Tuple(Vector{T}() for (_, T) in schema))
    open(Arrow.Writer, io, closeio=true) do writer
        st = nothing
        while true
            st = SQLiteDBS.nextcolumntable!(query,
                ct;
                batchsize = batchsize,
                state = st
            )
            Arrow.write(writer, ct)
            foreach(empty!, values(ct))
            st === nothing && break
        end
    end
end # toarrow

println("[Julia] Hello, Data!, We are ready")

end # module HelloData
