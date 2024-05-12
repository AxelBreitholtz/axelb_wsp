require 'slim'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'
require 'bcrypt'
require_relative 'model.rb'

enable :sessions

get('/') do
    id = session[:id].to_i  
    db = SQLite3::Database.new('db/fotboll.db')
    db.results_as_hash = true
    @result = db.execute("SELECT * FROM leagues ORDER BY leagues.id;")
    @user = db.execute("SELECT role FROM users WHERE id = ?", id)
    slim(:"ligor/index", locals: {results:@result, user:@user})
end

before('/protected/*') do
    p "These are protected methods"
    if session[:id] == nil
        redirect '/showlogin'
    end
end

before('/admin/*') do
    id = session[:id].to_i
    db = SQLite3::Database.new('db/fotboll.db')
    if db.execute("SELECT role from users WHERE id = ?",id).to_s.include?("admin")
    else
        p "detta är adminfunktionalitet"
        redirect("/")
    end
end


get('/protected/clubs/new') do 
    id = session[:id].to_i
    db = SQLite3::Database.new('db/fotboll.db')
    db.results_as_hash = true
    @result = db.execute("SELECT * FROM leagues")
    slim(:"klubbar/new", locals: {results:@result})
end 

post('/protected/clubs/new') do 
    db = SQLite3::Database.new('db/fotboll.db')
    club_names = db.execute("SELECT club_name FROM clubs WHERE club_name = ?", params[:klubbnamn])

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

# Tar bort klubbar (ska lägga till så att man kollar att den som tar bort äger klubben dvs om inloggat id tillhör klubben)
post('/protected/clubs/:id/delete') do
    id = params[:id].to_i
    db = SQLite3::Database.new('db/fotboll.db')
    user_id = db.execute("SELECT user_id FROM clubs WHERE id=?",id).first
    if user_id.first.to_i == session[:id].to_i
        db.execute("DELETE FROM clubs WHERE id = ?",id)
        # Tar även bort från relationstabellen
        db.execute("DELETE FROM leaguesclubs WHERE club_id = ?",id)
    else
        #Sinatra flash?
        p "du äger inte denna klubben"
    end
    redirect '/protected/clubs/index'
end

post('/protected/clubs/:id/update') do
    db = SQLite3::Database.new('db/fotboll.db')
    id = params[:id].to_i
    club_name = params[:club_name]
    rating = params[:rating]

    club_names = db.execute("SELECT club_name FROM clubs WHERE club_name = ?", club_name)

    user_id = db.execute("SELECT user_id FROM clubs WHERE id=?",id).first
    if user_id.first.to_i == session[:id].to_i
        if club_name && !club_name.empty?
            existing_club_names = db.execute("SELECT club_name FROM clubs WHERE club_name = ? AND id != ?", club_name, id)
            if existing_club_names.any?
                return "Klubbnamnet finns redan"
            end
        end

        # Check if the provided rating is within the valid range
        if rating && !rating.empty?
            rating_value = rating.to_i
            if rating_value < 0 || rating_value > 10
                return "Betyget måste vara mellan 0-10"
            end
        end

        # Update the club record
        db.execute("UPDATE clubs SET club_name = COALESCE(?, club_name), rating = COALESCE(?, rating) WHERE id = ?", club_name, rating, id)
    else
        #Sinatra flash?
        p "du äger inte denna klubben"
    end

    redirect('/protected/clubs/index')

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
    @league_result = db.execute("SELECT id,name from leagues")
    slim(:"/dina_klubbar/edit", locals: {results:@result,league_results:@league_result}) 
end

get('/admin/ligor/new') do 
    db = SQLite3::Database.new('db/fotboll.db')
    db.results_as_hash = true
    slim(:"/ligor/new", locals: {results:@result})
end

post('/admin/ligor/new') do 
    lignamn = params[:leaguename]
    db = SQLite3::Database.new('db/fotboll.db')
    db.results_as_hash = true
    db.execute("INSERT INTO leagues (name) VALUES (?)", lignamn)

    slim(:"/ligor/new", locals: {results:@result})
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

    if @result.nil?
        set_login_attempt(username)
        "Invalid Credentials"
        redirect '/showlogin' #kanske nåt error vi får se
    end
    
    pwdigest = @result["pwd"]
    id = @result["id"]
    if login_cooldown_expired(username)
        if BCrypt::Password.new(pwdigest) == password
            session.delete(:login_attempts)
            session[:id] = id
            redirect("/")
        else
            set_login_attempt(username)
            "Invalid Credentials"
        end
    else
        "Login cooldown aktiverad. Testa igen senare."
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

#funktioner som jag inte lyckas kalla från model.rb!!!

def login_cooldown_expired(username)
    max_login_attempts = 3  
    cooldown_time = 10
    last_attempt_time = session[:login_attempts]&.fetch(username, nil) # & för att ange att andra värdet kan vara nil och fetch för att få tag på hash
    if last_attempt_time.nil?
        return true
    end 
    if Time.now - last_attempt_time > cooldown_time 
        return true
    else
        return false
    end
end

def set_login_attempt(username)
    if session[:login_attempts].nil?
        session[:login_attempts] = {}
    end
    session[:login_attempts][username] = Time.now
end
