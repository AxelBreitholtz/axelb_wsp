module Model
    # Establishes a connection to the SQLite database.
    #
    # @return [SQLite3::Database] The SQLite database connection.   
    def get_database()
        db = SQLite3::Database.new('db/fotboll.db')
        db.results_as_hash = true
        return db
    end

    # Creates a hashed representation of the given password using bcrypt.
    #
    # @param [String] password The password to be hashed.
    # @return [String] The hashed password.
    def create_password(password)
        return BCrypt::Password.create(password)
    end

    # Creates a BCrypt::Password instance from the given password digest.
    #
    # @param [String] pwdigest The password digest to create the BCrypt::Password instance from.
    # @return [BCrypt::Password] The BCrypt::Password instance.
    def salt_password(pwdigest)
        return BCrypt::Password.new(pwdigest)
    end

    # Selects all leagues from the database.
    #
    # @param [SQLite3::Database] db The database connection.
    # @return [Array<Array>] An array containing the results of the query.
    def select_all_leagues(db)
        return db.execute("SELECT * FROM leagues ORDER BY leagues.id;")
    end

    # Selects the role of the user with the given ID from the database.
    #
    # @param [SQLite3::Database] db The database connection.
    # @param [Integer] id The ID of the user.
    # @return [Array<Array>] An array containing the results of the query.
    def select_user_role(db, id)
        return db.execute("SELECT role FROM users WHERE id = ?", id)
    end

    # Selects the club name from the database where club_name matches the given name.
    #
    # @param [SQLite3::Database] db The database connection.
    # @param [String] club_name The name of the club.
    # @return [Array<Array>] An array containing the results of the query.
    def select_clubname_where(db, club_name)
        return db.execute("SELECT club_name FROM clubs WHERE club_name = ?", club_name)
    end

    # Inserts a new club into the clubs table.
    #
    # @param [SQLite3::Database] db The database connection.
    # @param [String] klubbnamn The name of the club.
    # @param [Integer] rating The rating of the club.
    # @param [Integer] id The ID of the user.
    def insert_into_clubs(db, klubbnamn, rating, id)
        db.execute("INSERT INTO clubs (club_name, rating, user_id) VALUES (?, ?, ?)", klubbnamn, rating, id)
    end

    # Inserts a new record into the leaguesclubs table.
    #
    # @param [SQLite3::Database] db The database connection.
    # @param [Integer] league_id The ID of the league.
    # @param [Integer] club_id The ID of the club.
    def insert_into_leaguesclubs(db, league_id, club_id)
        db.execute("INSERT INTO leaguesclubs (league_id, club_id) VALUES (?, ?)", league_id, club_id)
    end

    # Selects all clubs associated with the given user ID from the database.
    #
    # @param [SQLite3::Database] db The database connection.
    # @param [Integer] id The ID of the user.
    # @return [Array<Array>] An array containing the results of the query.
    def select_all_clubs_where(db, id)
        db.execute("SELECT * FROM clubs WHERE user_id = ? ORDER BY rating DESC;", id)
    end

    # Performs an inner join on the leaguesclubs and clubs tables to select clubs associated with the given league ID.
    #
    # @param [SQLite3::Database] db The database connection.
    # @param [Integer] league_id The ID of the league.
    # @return [Array<Array>] An array containing the results of the query.
    def innerjoin_leaguesclubs(db, league_id)
        sql_code = "
        SELECT clubs.club_name, clubs.rating FROM leagues
        INNER JOIN leaguesclubs ON leagues.id = leaguesclubs.league_id
        INNER JOIN clubs ON clubs.id = leaguesclubs.club_id
        WHERE leagues.id = ?
        ORDER BY clubs.rating DESC;
        "
        return db.execute(sql_code, league_id)
    end

    # Selects the user ID associated with the given club ID from the database.
    #
    # @param [SQLite3::Database] db The database connection.
    # @param [Integer] id The ID of the club.
    # @return [Array<Array>] An array containing the results of the query.
    def select_userid_clubs_where(db, id)
        return db.execute("SELECT user_id FROM clubs WHERE id=?", id)
    end

    # Deletes a club from the clubs table based on the given ID.
    #
    # @param [SQLite3::Database] db The database connection.
    # @param [Integer] id The ID of the club to delete.
    def delete_clubs_where(db, id)
        db.execute("DELETE FROM clubs WHERE id = ?", id)
    end

    # Deletes records from the leaguesclubs table where the club ID matches the given ID.
    #
    # @param [SQLite3::Database] db The database connection.
    # @param [Integer] id The ID of the club.
    def delete_leagues_clubs_where(db, id)
        db.execute("DELETE FROM leaguesclubs WHERE club_id = ?", id)
    end

    # Checks if a club with the given name and ID exists in the database.
    #
    # @param [SQLite3::Database] db The database connection.
    # @param [String] club_name The name of the club.
    # @param [Integer] id The ID of the club.
    # @return [Array<Array>] An array containing the results of the query.
    def club_exist?(db, club_name, id)
        db.execute("SELECT club_name FROM clubs WHERE club_name = ? AND id != ?", club_name, id)
    end

    # Updates the club name and rating in the clubs table based on the given ID.
    #
    # @param [SQLite3::Database] db The database connection.
    # @param [String] club_name The new name of the club.
    # @param [Integer] rating The new rating of the club.
    # @param [Integer] id The ID of the club to update.
    def update_clubs_coalesce(db, club_name, rating, id)
        db.execute("UPDATE clubs SET club_name = COALESCE(?, club_name), rating = COALESCE(?, rating) WHERE id = ?", club_name, rating, id)
    end


        # Selects the first club record from the clubs table based on the given ID.
    #
    # @param [SQLite3::Database] db The database connection.
    # @param [Integer] id The ID of the club.
    # @return [Hash, nil] The first club record if found, nil otherwise.
    def select_clubs_where_first(db, id)
        return db.execute("SELECT * FROM clubs WHERE id = ?", id).first
    end

    # Selects the IDs and names of all leagues from the database.
    #
    # @param [SQLite3::Database] db The database connection.
    # @return [Array<Array>] An array containing pairs of league ID and name.
    def select_id_name_leagues(db)
        db.execute("SELECT id, name FROM leagues")
    end

    # Inserts a new league into the leagues table.
    #
    # @param [SQLite3::Database] db The database connection.
    # @param [String] lignamn The name of the league to be inserted.
    def insert_into_leagues(db, lignamn)
        db.execute("INSERT INTO leagues (name) VALUES (?)", lignamn)
    end

    # Register a new user into the users table.
    #
    # @param [SQLite3::Database] db The database connection.
    # @param [String] password_digest The hashed password of the user.
    # @param [String] username The username of the user.
    def register_user(db, password_digest, username)
        db.execute("INSERT INTO users (pwd, username) VALUES (?, ?)", password_digest, username)
    end

    # Selects the first user record from the users table based on the given username.
    #
    # @param [SQLite3::Database] db The database connection.
    # @param [String] username The username of the user.
    # @return [Hash, nil] The first user record if found, nil otherwise.
    def select_users_where_first(db, username)
        return db.execute("SELECT * FROM users WHERE username = ?", username).first
    end

    # Updates the emblem filename of a club in the clubs table based on the given club ID.
    #
    # @param [SQLite3::Database] db The database connection.
    # @param [String] filename The filename of the emblem.
    # @param [Integer] club_id The ID of the club.
    def update_club_emblem(db, filename, club_id)
        db.execute("UPDATE clubs SET club_emblem = ? WHERE id = ?", filename, club_id)
    end

    # Validates the input data for creating a new club.
    #
    # @param [String] rating The rating of the club.
    # @param [String] klubbnamn The name of the club.
    # @param [Array<String>] club_names The existing club names.
    # @return [Boolean] true if input is valid, false otherwise.
    def validation_input_club(rating, klubbnamn, club_names)
        return rating.to_i.between?(0, 10) && klubbnamn != nil && club_names.empty?
    end

    # Validates the update of club name.
    #
    # @param [SQLite3::Database] db The database connection.
    # @param [String] club_name The name of the club.
    # @param [Integer] id The ID of the club.
    # @return [Boolean] true if club name is valid for update, false otherwise.
    def validation_update_clubname(db, club_name, id)
        return !club_name.nil? && club_exist?(db, club_name, id)
    end

    # Validates the update of club rating.
    #
    # @param [SQLite3::Database] db The database connection.
    # @param [String] rating The rating of the club.
    # @return [Boolean] true if rating is valid for update, false otherwise.
    def validation_update_rating(db, rating)
        return !rating.nil? && rating.to_i.between?(0, 10)
    end

    # Checks if the password and password confirmation match.
    #
    # @param [String] password The password.
    # @param [String] password_confirm The password confirmation.
    # @return [Boolean] true if passwords match, false otherwise.
    def password_input_check(password, password_confirm)
        return password == password_confirm
    end

    # Checks if a user list is empty, indicating that the user does not exist.
    #
    # @param [Array] user_list The list of users.
    # @return [Boolean] true if user does not exist, false otherwise.
    def user_not_exist?(user_list)
        return user_list.nil?
    end

    # Checks if the given password matches the hashed password.
    #
    # @param [String] pwdigest The hashed password.
    # @param [String] password The password to be checked.
    # @return [Boolean] true if passwords match, false otherwise.
    def password_check(pwdigest, password)
        return salt_password(pwdigest) == password
    end

    # Checks if both the file and filename exist.
    #
    # @param [Object] file The file object.
    # @param [String] filename The filename.
    # @return [Boolean] true if both file and filename exist, false otherwise.
    def file_exist?(file, filename)
        return file && filename
    end

    def check_last_attempt_time(last_attempt_time)
        max_login_attempts = 3  
        cooldown_time = 10
        if last_attempt_time.nil?
            return true
        end 
        if Time.now - last_attempt_time > cooldown_time 
            return true
        else
            return false
        end
    end

    def write_file(path,file)
        File.open(path,'wb') do |image|
            image.write(file.read)
        end
    end
end