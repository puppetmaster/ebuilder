lib = File.expand_path(File.dirname(__FILE__) + '/../lib')
$LOAD_PATH.unshift(lib) if File.directory?(lib) && !$LOAD_PATH.include?(lib)

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

require 'app/slave'
require 'app/project'

DataMapper.auto_upgrade!

