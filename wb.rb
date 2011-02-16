require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-migrations'

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

# App
#

# Afficher un Slave
get '/slave/:id' do
  @slave = Slave.get(params[:id])
  erb :slave
end

# Création d'un Slave
get '/slave/new' do
  erb :newslave
end

post '/slave/create' do 
  slave = Slave.new(:name => params[:name])
  slave.ip = params[:ip]
  slave.user = params[:user]
  slave.pass = params[:pass]
  if slave.save
    status 201
    redirect '/slave/' + slave.id.to_s
  else
    status 412
    redirect '/slaves/'
  end
end





DataMapper.auto_upgrade!

