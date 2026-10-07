module HelloData

using TOML

include("schemas.jl")

export SQLiteDBS

include("sqlitedbs.jl")

using .SQLiteDBS, Arrow, SQLite


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
    names = Tuple(first.(schema))
    open(Arrow.Writer, io, closeio=true) do writer
        st = nothing
        while true
            ct = NamedTuple{names}(Tuple(Vector{T}() for (_, T) in schema))
            st = SQLiteDBS.nextcolumntable!(query,
                ct;
                batchsize = batchsize,
                state = st
            )
            Arrow.write(writer, ct)
            st === nothing && break
        end
    end
end # toarrow

println("[Julia] Hello, Data!, We are ready")

end # module HelloData
