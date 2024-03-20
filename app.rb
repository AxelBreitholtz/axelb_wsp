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
    db = SQLite3::Database.new('db/fotboll.db')
    db.execute("DELETE FROM clubs WHERE id = ?",id)
    redirect '/clubs/index'
end

post('/clubs/:id/update') do
    id = params[:id].to_i
    club_name = params[:club_name]
    rating = params[:rating]
    league_id = params[:league_id]
    db = SQLite3::Database.new('db/fotboll.db')
    db.execute("UPDATE clubs SET club_name=?,rating=? WHERE id=?",club_name,rating,id)
    redirect('/clubs/index')
end

post('/clubs/:id/add') do
    id = params[:id].to_i
    league_id = params[:league_id]
    db = SQLite3::Database.new('db/fotboll.db')
    db.execute("INSERT INTO leaguesclubs (league_id,club_id) VALUES (?,?)",league_id,id)
    redirect('/clubs/index')
end

get('/clubs/:id/edit') do
    id = params[:id].to_i
    db = SQLite3::Database.new('db/fotboll.db')
    db.results_as_hash = true
    @result = db.execute("SELECT * FROM clubs WHERE id = ?",id).first
    slim(:"/dina_klubbar/edit", locals: {result:@result}) 
end