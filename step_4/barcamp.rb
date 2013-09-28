require 'rubygems'
require 'sinatra'

# The default listen IP address for Sinatra is localhost not 0.0.0.0. This
# makes it so we cannot connect to this server from outside our virtual
# machine.
# http://www.sinatrarb.com/configuration.html#bind---server-hostname-or-ip-address
set :bind, '0.0.0.0'

get '/' do
  @file_names = []

  # Loop through all of the .jpg files in the random-images directory
  Dir.glob('/vagrant/public/random-images/*.jpg', File::FNM_CASEFOLD) do |filename|
    @file_names.push File.basename(filename)
  end

  erb :index
end