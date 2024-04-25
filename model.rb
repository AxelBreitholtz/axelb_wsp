

def login_cooldown_expired(username)
    max_login_attempts = 3  
    cooldown_time = 60
    p 'jag kom hit'
    last_attempt_time = session[:login_attempts]&.fetch(username, nil)- # & för att ange att andra värdet kan vara nil och fetch för att få tag på hash
    if last_attempt_time.nil?
        p 'expired'
        return true
    end 
    p Time.now - last_attempt_time
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
    p 'test:'
    p session[:login_attempts][username]
end



