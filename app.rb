require 'slim'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'
require 'bcrypt'

enable :sessions

get('/') do
    db = SQLite3::Database.new('db/fotboll.db')
    db.results_as_hash = true
    @result = db.execute("SELECT * FROM leagues ORDER BY leagues.id;")
    slim(:"ligor/index", locals: {results:@result})
end

before('/protected/*') do
    p "These are protected methods"
    if session[:id] == nil
        redirect '/showlogin'
    end
end

get('/protected/clubs/new') do 
    slim(:"klubbar/new")
end 

post('/protected/clubs/new') do 
    db = SQLite3::Database.new('db/fotboll.db')
    club_names = db.execute("SELECT club_name FROM clubs WHERE club_name = ?", params[:klubbnamn])
    p club_names.length
    p params[:rating].to_i
    p params[:klubbnamn]


    if params[:rating].to_i <= 10 && params[:rating].to_i >= 0 && params[:klubbnamn] != nil && club_names.length == 0
        id = session[:id]
        klubbnamn = params[:klubbnamn]
        rating = params[:rating].to_i
        league_id = params[:league_id].to_i
        db = SQLite3::Database.new('db/fotboll.db')
        db.execute("INSERT INTO clubs (club_name,rating,user_id) VALUES (?,?,?)",klubbnamn,rating,id)
        club_Id = db.execute("SELECT id FROM clubs ORDER BY id DESC LIMIT 1;")
        db.execute("INSERT INTO leaguesclubs (league_id,club_id) VALUES (?,?)",league_id,club_Id)
        redirect '/protected/clubs/new'
    else
        "Betyget måste vara mellan 1-10 eller tomt namn"
    end
end

get('/protected/clubs/index') do
    id = session[:id].to_i
    db = SQLite3::Database.new('db/fotboll.db')
    db.results_as_hash = true
    @result = db.execute("SELECT * FROM clubs WHERE user_id = ? ORDER BY rating DESC;",id)
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

post('/protected/clubs/:id/delete') do
    id = params[:id].to_i
    db = SQLite3::Database.new('db/fotboll.db')
    db.execute("DELETE FROM clubs WHERE id = ?",id)
    redirect '/protected/clubs/index'
end

post('/protected/clubs/:id/update') do
    db = SQLite3::Database.new('db/fotboll.db')
    club_names = db.execute("SELECT club_name FROM clubs WHERE club_name = ?", params[:club_name])
    
    #MÅSTE ÄNDRA SÅ ATT DET INTE BLIR ERROR NÄR MAN INTE BYTER NAMN
    if params[:rating].to_i <= 10 && params[:rating].to_i >= 0 && params[:club_name] != nil && club_names.length == 0
        id = params[:id].to_i
        club_name = params[:club_name]
        rating = params[:rating]
        league_id = params[:league_id]
        db.execute("UPDATE clubs SET club_name=?,rating=? WHERE id=?",club_name,rating,id)
        redirect('/protected/clubs/index')
    else
        "Betyget måste vara mellan 1-10 eller tomt namn"
    end

end

post('/protected/clubs/:id/new') do
    id = params[:id].to_i
    league_id = params[:league_id]
    db = SQLite3::Database.new('db/fotboll.db')
    db.execute("INSERT INTO leaguesclubs (league_id,club_id) VALUES (?,?)",league_id,id)
    redirect('/protected/clubs/index')
end

get('/protected/clubs/:id/edit') do
    id = params[:id].to_i
    db = SQLite3::Database.new('db/fotboll.db')
    db.results_as_hash = true
    @result = db.execute("SELECT * FROM clubs WHERE id = ?",id).first
    slim(:"/dina_klubbar/edit", locals: {result:@result}) 
end

get('/showregister') do
    slim(:register)
end

get('/showlogin') do
    slim(:login)
end

post('/users/new') do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]

    if (password == password_confirm)
        password_digest = BCrypt::Password.create(password)
        db = SQLite3::Database.new('db/fotboll.db')
        db.execute("INSERT INTO users (pwd,username) VALUES (?,?)",password_digest, username)
        redirect("/")
    else
        "Lösenord matchar inte"
    end
end

post('/login') do
    username = params[:username]
    password = params[:password]
    db = SQLite3::Database.new('db/fotboll.db')
    db.results_as_hash = true
    @result = db.execute("SELECT * FROM users WHERE username = ?", username).first
    pwdigest = @result["pwd"]
    id = @result["id"]

    if BCrypt::Password.new(pwdigest) == password
        session[:id] = id
        redirect("/")
    else
        "FEL LÖSENORD"
    end
end

post('/logout') do
    session[:id] = nil
    redirect '/showlogin'
end

# VÄLDIGT FUL KOD 
post('/protected/:id/upload_image') do
    if params[:file] && params[:file][:filename]
        filename = params[:file][:filename]
        file = params[:file][:tempfile]
        path = "./public/uploads/#{filename}"

        File.open(path,'wb') do |image|
            image.write(file.read)
        end

        club_id = params[:id]
        p "detta är club id"
        p club_id
        db = SQLite3::Database.new('db/fotboll.db')
        db.execute("UPDATE clubs SET club_emblem=? WHERE id = ?",filename,club_id)
    end
    redirect '/protected/clubs/index'
end 