lib = File.expand_path(File.dirname(__FILE__) + '/../lib')
$LOAD_PATH.unshift(lib) if File.directory?(lib) && !$LOAD_PATH.include?(lib)

point = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift(point) if File.directory?(point) && !$LOAD_PATH.include?(point)

require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-migrations'
require 'haml'

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/db/test.db")


require 'models/buildopt'
require 'models/slave'
require 'models/project'
require 'models/build'



#
# Apps
#

$menu = {}

$menu[:Home] = "/"

require 'app/slave'
require 'app/project'
require 'app/build'
require 'app/buildopt'

get '/' do 
  @projects = Project.all
  @builds = Build.all
  @slaves = Slave.all
  haml :home
end

DataMapper.auto_upgrade!

