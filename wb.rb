require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-migrations'
require 'haml'

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/test.db")

class Buildopt
  include DataMapper::Resource

#  property :id, Serial
  property :opt, String, :key => true
  #, :unique_index => true
  #property :opt, String, :unique_index => true

  belongs_to :project, :key => true
  belongs_to :slave,   :key => true

  def show
    puts "#{@opt} for #{@project} in #{@slave}"
  end
end

class Slave
  include DataMapper::Resource

  property :id,   Serial
  property :name, String, :unique_index => true
  property :ip,   String
  property :user, String
  property :pass, String

  has n, :build
  has n, :project, :through => :build
  has n, :buildopt

end

class Project
  include DataMapper::Resource

  property :id,     Serial
  property :name,   String, :unique_index => true
  property :url,    String
  property :period, String

  has n, :build
  has n, :slave, :through => :build
  has n, :buildopt

  def show
    puts "----------------------------------------------------------"
    puts " NAME       : #{@name}"
    puts " URL        : #{@url}"
    puts " Build each : #{@period}"
    puts "----------------------------------------------------------"
  end

end

class Build
  include DataMapper::Resource

  property :id,         Serial
  property :start_date, DateTime, :required => true
  property :end_date,   DateTime #, :required => false
  property :result,     Integer #  :required => false=

  belongs_to :slave,   :key => true
  belongs_to :project, :key => true
  has n, :buildopt, :through => :slave , :via => :target
#  has n, :buildopt, :through => :project 

  def show
    puts "----------------------------------------------------------"
    puts "Build #{@id}"
    puts "----------------------------------------------------------"
    puts " Build of : #{self.project.name}"
    puts " Build on : #{self.slave.name}"
    puts "----------------------------------------------------------"
    puts "  Started on    : #{@start_date}"
    puts "  Ended on      : #{@end_date}"
    puts "  Duration      : #{@end_date - @start_date}"
    puts "  Result        : #{@result}"
    puts "  Build Options :"
    self.buildopt.each do |bo|
      puts "   #{bo.key}"
    end
    puts "----------------------------------------------------------"
  end

end

#
# APPLICATION WEB !
#
#
get '/' do 
  haml :home
end

# Slave thing

get '/slave/' do
  @slaves = Slave.all
  if @slaves.empty?
    haml :'/slave/newslave'
  else
    haml :'slave/slave'
  end
end

get '/slave/show/:id' do
  @slave = Slave.get(params[:id])
  haml :'/slave/slaveshow'
end

# Création d'un Slave
get '/slave/new' do
  haml :'/slave/newslave'
end

get '/slave/edit/:id' do
  @slave = Slave.get(params[:id])
  haml :'slave/slaveedit'
end

post '/slave/update' do
  slave = Slave.get(params[:id])
  slave.attribute_set(:name,params[:name])
  slave.attribute_set(:ip,params[:ip])
  slave.attribute_set(:user,params[:user])
  if params[:pass] != "nochange"
    slave.attribute_set(:pass,params[:pass])
  end

  if slave.save
    status 201
    redirect '/slave/show/' + slave.id.to_s
  else
    status 412
    redirect '/slave/'
  end
end

post '/slave/create' do 
  slave = Slave.new(:name => params[:name])
  slave.ip = params[:ip]
  slave.user = params[:user]
  slave.pass = params[:pass]
  if slave.save
    status 201
    redirect '/slave/show/' + slave.id.to_s
  else
    status 412
    redirect '/slave/'
  end
end

get '/slave/delete/:id' do
  slv = Slave.get(params[:id])
  if slv.destroy
    redirect '/slave/'
  else
    redirect '/slave/' #FIXME CLEAN INFORMATION
  end
end

delete '/slave/:id' do 
  slv = Slave.get(params[:id])
  if slv.destroy
    redirect '/slave'
  else
    redirect '/slave' #FIXME CLEAN INFORMATION
  end
end

# Project Thing 
get '/project/' do
  @projects = Project.all
  if @projects.empty?
    haml :'project/newproject'
  else
    haml :'project/project'
  end
end

get '/project/show/:id' do
  @project = Project.get(params[:id])
  haml :'project/projectshow'
end


get '/project/edit/:id' do
  @project = Project.get(params[:id])
  haml :'project/projectedit'
end

# Création d'un project
get '/project/new' do
  haml :'project/newproject'
end

get '/project/delete/:id' do
  slv = Project.get(params[:id])
  if slv.destroy
    redirect '/project/'
  else
    redirect '/project/' #FIXME CLEAN INFORMATION
  end
end

delete '/project/:id' do 
  slv = Project.get(params[:id])
  if slv.destroy
    redirect '/project/'
  else
    redirect '/project/' #FIXME CLEAN INFORMATION
  end
end

post '/project/update' do
  project = Project.get(params[:id])
  project.attribute_set(:url,params[:url])
  project.attribute_set(:period,params[:period])
  if project.save
    status 201
    redirect '/project/show/' + project.id.to_s
  else
    status 412
    redirect '/project/'
  end
end

post '/project/create' do 
  project = Project.new(:name => params[:name])
  project.url = params[:url]
  project.period = params[:period]
  if project.save
    status 201
    redirect '/project/show/' + project.id.to_s
  else
    status 412
    redirect '/project/'
  end
end

DataMapper.auto_upgrade!

