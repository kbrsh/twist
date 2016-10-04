require 'sinatra'
require 'data_mapper'
require 'haml'

# Setup db
DataMapper::setup(:default,"sqlite3://#{Dir.pwd}/arrow.db")

# 404 Page
error Sinatra::NotFound do
  content_type 'text/plain'
  [404, '404 Not Found']
end
