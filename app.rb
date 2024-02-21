require 'slim'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'

get('/') do
    db = SQLite3::Database.new('db/fotboll.db')
    db.results_as_hash = true
    @result = db.execute("SELECT * FROM league")
    p @result
    slim(:"ligor/index", locals: {ligor:@result})
end