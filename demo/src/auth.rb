require 'tmpdir'
$LOAD_PATH << File.join(File.dirname(__FILE__), "../src")
require 'messages'

class PasswordFile
  attr :path
  
  def initialize(passwords_file_path="#{Dir.tmpdir}/pwds.txt")
    @path = passwords_file_path
  end
  
  def get_users()
    user_accounts = {}
    if File.exists?(@path)
      password_file = File.open(@path)
      password_file.each_line do |acct|
        data = acct.split("\t")
        user_accounts[data[0]] = {:name => data[0], :pwd => data[1], :status => data[2].chomp!.to_sym}
      end
      password_file.close
    end
    return user_accounts
  end
  
  def save(user_accounts)
    password_file = File.open(@path, "w")
    user_accounts.each do |userid, values|
      password_file.puts(userid + "\t" + values[:pwd] + "\t" + values[:status].to_s)
    end
    password_file.close
    get_users
  end
end

class Authentication
  attr :user_accounts
  attr :password_file
  attr :filepath
  attr :pwd_file
  
  def initialize(pwd_file)
    @pwd_file = pwd_file
    load_users
  end
  
  def load_users()
    @user_accounts = @pwd_file.get_users
  end
  
  def account_exists?(username)
    !@user_accounts[username].nil?
  end
  
  def create(username, password, status=:active)
    return :already_exists unless @user_accounts[username].nil?
    return :too_short unless Password.new(password).valid?
    account_data = {}
    account_data[:pwd] = password
    account_data[:status] = status
    @user_accounts[username] = account_data
    @pwd_file.save(@user_accounts)
    return :success
  end
  
  def login(username, password)
    if !@user_accounts[username].nil? && @user_accounts[username][:pwd] == password
      @user_accounts[username][:status] = :online
      @pwd_file.save(@user_accounts)
      return :logged_in
    else
      return :access_denied
    end
  end
  
  def get_user(name)
    return User.new(name, @user_accounts[name])
  end
end

class User
  attr :name
  attr :pwd
  attr :status
  
  def initialize(name, user_data)
    @name = name
    @pwd = user_data[:pwd]
    @status = user_data[:status]
  end
  
  def logged_in?
    return @status == :online
  end
  
  def password_equals(password)
    return password == @pwd
  end
end

# class Password
#   attr :password
#   
#   def initialize(password)
#     @password = password
#   end
#   
#   def valid?
#      if !contains_number? || !contains_letter? || too_short? || too_long? || !contains_punctuation? 
#        return false
#      else 
#       return true
#      end
#   end
#   
#   def too_short?
#     return (@password.length < 6)
#   end
#   
#   def too_long?
#     return (@password.length > 12)
#   end
#   
#   def contains_punctuation?
#     return !@password.match(/\W/).nil?
#   end
#   
#   def contains_letter?
#     return !@password.match(/[a-zA-Z]/).nil?
#   end
#   
#   def contains_number?
#     return !@password.match(/\d/).nil?
#   end
#   
# end

class CommandLine
  
  def self.CalledWith(auth, args)
    return Messages.lookup(:no_cmd) if args.nil?
    
    if auth.respond_to?(args[0].to_sym)
      return_code = auth.send(args[0].to_sym, args[1], args[2])
      return Messages.lookup(return_code)
    else
      return Messages.lookup(:unknown) + " '#{args[0]}'"
    end
  end
end

# if being called from the cmd line with args
if !(ARGV[0].nil?)

  # setup the authentication server
  pwd_file = PasswordFile.new()
  auth     = Authentication.new(pwd_file)

  # grab the input and write out the output to stdout
  puts CommandLine.CalledWith(auth, ARGV)

end
