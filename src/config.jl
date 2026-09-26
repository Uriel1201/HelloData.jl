module Config

const URI_POSTGRESQL = get(ENV, "URI_POSTGRESQL", nothing)
const URI_MYSQL      = get(ENV, "URI_MYSQL", nothing)
const ODB_DSN        = get(ENV, "ODB_DSN", nothing)
const ODB_USER       = get(ENV, "ODB_USER", nothing)
const ODB_PASSWORD.  = get(ENV, "ODB_PASSWORD", nothing)

end #module Config
