require 'sinatra'
require 'data_mapper'
require 'haml'

# Setup assets
set :public_folder, 'assets'

# Enable Sessions
enable :sessions

# Set Helpers
helpers do

  def login?
    if session[:username].nil?
      return false
    else
      return true
    end
  end

  def username
    return session[:username]
  end

end

# Setup db
DataMapper::setup(:default,"sqlite3://#{Dir.pwd}/arrow.db")

# User Data Structure
class User
  include DataMapper::Resource
	property :id, Serial
	property :username, String
  property :email, String
  property :password_salt, String
  property :password_hash, String

	has n, :links
end

# Data structure for link
class Link
  include DataMapper::Resource
  property :id, Serial
  property :title, String
  property :url, Text
  property :score, Integer
  property :points, Integer, :default => 0
  property :created_at, Time

  has n, :upvotes

  belongs_to :user

  attr_accessor :score

  def getScore
    time_elapsed = (Time.now - self.created_at) / 3600
    self.score = (self.points / time_elapsed) / 100
  end

  def self.sortLinksByScore
    self.all.each { |item| item.getScore }.sort { |a,b| a.score <=> b.score }.reverse
  end

end


class Upvote
  include DataMapper::Resource
	property :id, Serial
	property :ip_address, String

	belongs_to :link

	validates_uniqueness_of :ip_address, :scope => :link_id
end

# Setup DB
DataMapper.finalize.auto_upgrade!

# Routes

get '/' do
  @links = Link.sortLinksByScore
  haml :index
end

get '/create' do
  haml :create
end

get "/signup" do
  haml :signup
end

post "/signup" do
  password_salt = BCrypt::Engine.generate_salt
  password_hash = BCrypt::Engine.hash_secret(params[:password], password_salt)

  if(User.get params[:username])
    User.new(:username => params[:username], :email => params[:email], :password_salt => password_salt, :password_hash => password_hash)
    session[:username] = params[:username]
  end

  redirect "/"
end

post "/login" do
  if User.get params[:username]
    user = User.get params[:username]
    if user.password_hash == BCrypt::Engine.hash_secret(params[:password], user.password_salt)
      session[:username] = params[:username]
      redirect "/"
    end
  end
end

get "/logout" do
  session[:username] = nil
  redirect "/"
end

post '/create' do
  new_link = Link.new
  new_link.title = params[:title]
  new_link.url = params[:url]
  new_link.created_at = Time.now
  new_link.save
  redirect back
end

post '/:id/upvote' do
  linkToUpvote = Link.get params[:id]
  if linkToUpvote.upvotes.new(:ip_address => request.ip).save
     linkToUpvote.update(:points => linkToUpvote.points + 1)
  end
  redirect back
end

# 404 Page
error Sinatra::NotFound do
  content_type 'text/plain'
  [404, '404 Not Found']
end
