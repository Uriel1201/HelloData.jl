function database_config()
    Dict(
        :postgresql => ENV["URI_POSTGRESQL"],
        :mysql => ENV["URI_MYSQL"],
        :oracle_dsn => ENV["ODB_DSN"],
        :oracle_user => ENV["ODB_USER"],
        :oracle_password => ENV["ODB_PASSWORD"],
    )
end
