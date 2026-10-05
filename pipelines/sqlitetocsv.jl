using HelloData, DBInterface, SQLite, CSV, Tables

function loadfile(csvfile::String,
    columnames::Vector{Symbol},
    columntypes::Vector{Type}
)::CSV.Rows
    csvpath = joinpath(datadir(), "csv", csvfile)
    if isfile(csvpath)
        return CSV.Rows(csvpath;
            header=columnames,
            skipto=2,
            types=columntypes
        )
    else
        throw(ArgumentError("csvpath not found: $csvpath"))
    end
end




if Base.@isdefined(PROGRAM_FILE) && abspath(PROGRAM_FILE) == abspath(@__FILE__)
    main(ARGS[1], 
        ARGS[2], 
        ARGS[3]; 
        batchsize=parse(Int, ARGS[4])
    )
end
