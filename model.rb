def get_database()
    db = SQLite3::Database.new('db/fotboll.db')
    db.results_as_hash = true
    return db
end

