require 'slim'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'

get('/') do
    db = SQLite3::Database.new('db/fotboll.db')
    db.results_as_hash = true
    @result = db.execute("SELECT * FROM league")
    slim(:"ligor/index", locals: {results:@result})
end

get('/clubs/new') do 
    slim(:"klubbar/new")
end 

post('/clubs/new') do 
    klubbnamn = params[:klubbnamn]
    rating = params[:rating].to_i
    league_id = params[:league_id].to_i
    db = SQLite3::Database.new('db/fotboll.db')
    db.execute("INSERT INTO club (name,rating,league_id) VALUES (?,?,?)",klubbnamn,rating,league_id)
end

get('/clubs/index') do
    db = SQLite3::Database.new('db/fotboll.db')
    @result = db.execute("SELECT * FROM club")
    slim(:"klubbar/index", locals: {results:@result})
end