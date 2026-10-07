module HelloData

using TOML

include("schemas.jl")

export SQLiteDBS, toarrow

include("sqlitedbs.jl")

using .SQLiteDBS, Arrow, SQLite


function toarrow end

"""
    toarrow(query::SQLite.Query, 
        schema::Vector{Pair{Symbol, Type}},
        io::IO; 
        batchsize::Int=10000
    ) -> Nothing
Converts the contents of a SQLite.Query object to Arrow format 
and writes them to an IO object.

# Arguments 
- `query::SQLite.Query`                : The result of requesting data from a Sqlite table.
- `schema::Vector{Pair{Symbol, Type}}` : A vector of symbols and types that represents 
                                         the schema of the table.
- `io::IO`                             : An object that implements the IO interface 
                                         and can be used to read or write data.
- `batchsize::Int=10000` :             : The size of a batch that will be write by each iteration.

# Example 
```julia
julia> open(filepath, "w") do io
           HelloData.toarrow(sql,
               schema,
               io;
               batchsize=batchsize
           )
       end
```
"""
function toarrow(query::SQLite.Query,
    schema::Vector{Pair{Symbol, Type}},
    io::IO;
    batchsize::Int=10000
)::Nothing
    names = Tuple(first.(schema))
    open(Arrow.Writer, io, closeio=false) do writer
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
