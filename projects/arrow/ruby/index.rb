require 'sinatra'

# DataMapper::setup(:default,"sqlite3://#{Dir.pwd}/database.db")

error Sinatra::NotFound do
  content_type 'text/plain'
  [404, '404 Not Found']
end

set(:probability) { |value| condition { rand <= value } }
