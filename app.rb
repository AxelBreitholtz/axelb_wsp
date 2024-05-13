require 'slim'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'
require 'bcrypt'
require_relative './model.rb'

enable :sessions

include Model

# Display landing page and list of leagues
#
# @see Model#select_all_leagues
# @see Model#select_user_role
get('/') do
    id = session[:id].to_i
    db = get_database()
    @result = select_all_leagues(db)
    @user = select_user_role(db, id)
    slim(:"ligor/index", locals: {results: @result, user: @user})
end

# Executed before any routes matching '/protected/*'.
before('/protected/*') do
    p "These are protected methods"
    if session[:id] == nil
        redirect '/showlogin'
    end
end

# Executed before any routes matching '/admin/*'.
before('/admin/*') do
    id = session[:id].to_i
    db = get_database()
    if select_user_role(db,id).to_s.include?("admin")
    else
        p "detta är adminfunktionalitet"
        redirect("/")
    end
end

# Handles the GET request to display the form for creating a new club.
#
# @see Model#get_database
# @see Model#select_all_leagues
get('/protected/clubs/new') do 
    id = session[:id].to_i
    db = get_database()
    @result = select_all_leagues(db)
    slim(:"klubbar/new", locals: {results: @result})
end


# Handles the POST request to create a new club.
#
# @param [Hash] params The parameters sent with the request.
# @param[String] klubbnamn, the clubname
# @param [Integer] rating, the rating of the new club.
# @param [String] league_id, id of the league which the club belongs to
# 
# @see Model#get_database
# @see Model#select_clubname_where
# @see Model#validation_input_club
# @see Model#insert_into_clubs
# @see Model#insert_into_leaguesclubs
post('/protected/clubs/new') do 
    db = get_database()
    club_names = select_clubname_where(db, params[:klubbnamn])

    if validation_input_club(params[:rating], params[:klubbnamn], club_names)
        id = session[:id]
        klubbnamn = params[:klubbnamn]
        rating = params[:rating].to_i
        league_id = params[:league_id].to_i
        insert_into_clubs(db, klubbnamn, rating, id)
        club_id = db.last_insert_row_id
        insert_into_leaguesclubs(db, league_id, club_id)
        redirect '/protected/clubs/new'
    else
        "Betyget måste vara mellan 1-10 eller tomt namn"
    end
end

# Displays all the clubs that are owned by the logged-in user
#
# @see Model#get_database
# @see Model#select_all_clubs_where
get('/protected/clubs/index') do
    id = session[:id].to_i
    db = get_database()
    @result = select_all_clubs_where(db, id)
    slim(:"dina_klubbar/index", locals: {results: @result})
end

# Displays all clubs associated with the league id
#
# @param [Integer] league_id, id of the league.
#
# @see Model#get_database
# @see Model#innerjoin_leaguesclubs
get('/clubs/index/:league_id') do
    db = get_database()
    @result = innerjoin_leaguesclubs(db, params[:league_id])
    slim(:"klubbar/index", locals: {results: @result})
end

# Handles the deletion of a club and redirects to '/protected/clubs/index'
#
# @param [Integer] id, id of the club to be deleted.
# 
# @see Model#get_database
# @see Model#select_userid_clubs_where
# @see Model#delete_clubs_where
# @see Model#delete_leagues_clubs_where
post('/protected/clubs/:id/delete') do
    id = params[:id].to_i
    db = get_database()
    user_id = select_userid_clubs_where(db, id).first
    if user_id.first[1].to_i == session[:id].to_i
        delete_clubs_where(db, id)
        delete_leagues_clubs_where(db, id)
    else
        "du äger inte denna klubben"
    end
    redirect '/protected/clubs/index'
end


# Handles the update of a club and redirects to '/protected/clubs/index'
#
# @param [Integer] id, ID of the club to be updated.
# @param [String] club_name, updated name of the club.
# @param [Integer] rating, updated rating of the club.
#
# @see Model#get_database
# @see Model#select_clubname_where
# @see Model#select_userid_clubs_where
# @see Model#validation_update_clubname
# @see Model#validation_update_rating
# @see Model#update_clubs_coalesce
post('/protected/clubs/:id/update') do
    db = get_database()
    id = params[:id].to_i
    club_name = params[:club_name]
    rating = params[:rating]
    club_names = select_clubname_where(db, club_name)
    user_id = select_userid_clubs_where(db, id).first

    if user_id.first[1].to_i == session[:id].to_i
        if validation_update_clubname(db, club_name, id)
            return "Klubbnamnet finns redan"
        end
        if validation_update_rating(db, rating)
            return "Betyget måste vara mellan 0-10"
        end
        update_clubs_coalesce(db, club_name, rating, id)
    else
        "du äger inte denna klubben"
    end
    redirect('/protected/clubs/index')
end

# Handles the addition of a new club to a league and redirects to '/protected/clubs/index'
#
# @param [Integer] id The ID of the club to be added to the league.
# @param [Integer] league_id The ID of the league to which the club is being added.
#
# @see Model#get_database
# @see Model#insert_into_leaguesclubs
post('/protected/clubs/:id/new') do
    id = params[:id].to_i
    league_id = params[:league_id]
    db = get_database()
    insert_into_leaguesclubs(db, league_id, id)
    redirect('/protected/clubs/index')
end

# Renders the edit page for a specific club.
#
# @param [Integer] id, id of the club to be edited.
# 
# @see Model#get_database
# @see Model#select_clubs_where_first
# @see Model#select_id_name_leagues
get('/protected/clubs/:id/edit') do
    id = params[:id].to_i
    db = get_database()
    @result = select_clubs_where_first(db, id)
    @league_result = select_id_name_leagues(db)
    slim(:"/dina_klubbar/edit", locals: {results: @result, league_results: @league_result}) 
end

# Opening the database for creating a new league.
#
# @see Model#get_database
get('/admin/ligor/new') do 
    db = get_database()
    slim(:"/ligor/new", locals: {results: @result})
end

# Handles the creation of a new league.
#
# @param [String] lignamn, leaguename.
# 
# @see Model#get_database
# @see Model#insert_into_leagues
post('/admin/ligor/new') do 
    lignamn = params[:leaguename]
    db = get_database()
    insert_into_leagues(db, lignamn)
    slim(:"/ligor/new", locals: {results: @result})
end

# Display the registration page.
get('/showregister') do
    slim(:register)
end

# Displays a login form
get('/showlogin') do
    slim(:login)
end

# Handles the creation of a new user account and redirect to home page.
#
# @param [String] username, The new username 
# @param [String] password, The new password
# @param [String] password_confirm, The confirmation of the password.
post('/users/new') do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]

    if password_input_check(password, password_confirm)
        password_digest = create_password(password)
        db = get_database()
        register_user(db, password_digest, username)
        redirect("/")
    else
        "Lösenord matchar inte"
    end
end

# Handles the user login process and redirect to homepage after succesful login.
#
# @param [String] username, The username 
# @param [String] password, The password 
# 
# @see Model#get_database
# @see Model#select_users_where_first
# @see Model#login_cooldown_expired
# @see Model#password_check
# @see Model#set_login_attempt
post('/login') do
    username = params[:username]
    password = params[:password]
    db = get_database()

    @result = select_users_where_first(db, username)
    if user_not_exist?(@result)
        set_login_attempt(username)
        "Invalid Credentials"
        redirect '/showlogin' 
    end
    
    pwdigest = @result["pwd"]
    id = @result["id"]
    
    if login_cooldown_expired(username)
        if password_check(pwdigest, password)
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

# Logout user and redirect to login form
post('/logout') do
    session[:id] = nil
    redirect '/showlogin'
end

# Upload a club emblem and redirect to /protected/clubs/index.
#
# @param [Hash] params, The parameters
# 
# @see Model#get_database
# @see Model#file_exist?
# @see Model#write_file
# @see Model#update_club_emblem
post('/protected/:id/upload_image') do
    if file_exist?(params[:file], params[:file][:filename])
        filename = params[:file][:filename]
        file = params[:file][:tempfile]
        path = "./public/uploads/#{filename}"

        write_file(path, file)

        club_id = params[:id]
        db = get_database()
        update_club_emblem(db, filename, club_id)
    end
    redirect '/protected/clubs/index'
end 

# Checks if the login cooldown period has expired.
#
# @param [String] username, The username which the cooldown is checked.
def login_cooldown_expired(username)
    last_attempt_time = session[:login_attempts]&.fetch(username, nil)
    check_last_attempt_time(last_attempt_time)
end

# Sets the login attempt time for a given username.
#
# @param [String] username, The username which the login attempt time is set for .
def set_login_attempt(username)
    if session[:login_attempts].nil?
        session[:login_attempts] = {}
    end
    session[:login_attempts][username] = Time.now
end
