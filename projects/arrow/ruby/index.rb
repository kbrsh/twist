require 'sinatra'
require 'data_mapper'
require 'haml'

# Setup assets
set :public_folder, 'assets'

# Enable Sessions
enable :sessions

# Setup db
DataMapper::setup(:default,"sqlite3://#{Dir.pwd}/arrow.db")

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
