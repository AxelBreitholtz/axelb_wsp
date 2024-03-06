require 'slim'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'

get('/') do
    db = SQLite3::Database.new('db/fotboll.db')
    db.results_as_hash = true
    @result = db.execute("SELECT * FROM leagues ORDER BY leagues.id;")
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
    db.execute("INSERT INTO clubs (club_name,rating) VALUES (?,?)",klubbnamn,rating)
    club_Id = db.execute("SELECT id FROM clubs ORDER BY id DESC LIMIT 1;")
    db.execute("INSERT INTO leaguesclubs (league_id,club_id) VALUES (?,?)",league_id,club_Id)
    redirect '/clubs/new'
end

get('/clubs/index') do
    db = SQLite3::Database.new('db/fotboll.db')
    db.results_as_hash = true
    @result = db.execute("SELECT * FROM clubs ORDER BY club_name ASC;")
    slim(:"dina_klubbar/index", locals: {results:@result})
end

get('/clubs/index/:league_id') do
    db = SQLite3::Database.new('db/fotboll.db')
    db.results_as_hash = true
    sql_code = "
    SELECT clubs.club_name, clubs.rating FROM leagues
    INNER JOIN leaguesclubs ON leagues.id = leaguesclubs.league_id
    INNER JOIN clubs ON clubs.id = leaguesclubs.club_id
    WHERE leagues.id = ?
    ORDER BY clubs.rating DESC;
    "
    @result = db.execute(sql_code,[params[:league_id]])
    slim(:"klubbar/index", locals: {results:@result})
end

post('/clubs/:id/delete') do
    id = params[:id].to_i

    redirect '/clubs/index'
end