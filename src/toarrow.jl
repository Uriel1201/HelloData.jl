using Arrow, SQLite
using .SQLiteDBS

function toarrow end

"""
    toarrow(query::SQLite.Query, io::IO; batchsize::Int64=10000) -> Nothing 
"""
function toarrow(query::SQLite.Query,
    schema::Vector{Pair{Symbol, Type}},
    io::IO; 
    batchsize::Int64=10000
)::Nothing 
    try
        ct = NamedTuple{Tuple(first.(schema))}(Tuple(Vector{T}() for (_, T) in schema))
        open(Arrow.Writer, io, closeio=false) do writer
            state = nothing 
            while true
                st = SQLiteDBS.nextcolumntable!(query, 
                    ct; 
                    batchsize = batchsize, 
                    state = state
                )
                Arrow.write(writer, ct)
                foreach(empty!, values(ct))
                state = st
                st === nothing && break
            end
        end
    catch e
        @error "action failed" exception=(e, catch_backtrace())
        rethrow()
    end
end # toarrow
