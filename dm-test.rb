#!/usr/bin/ruby
#

require 'rubygems'
require 'dm-core'
require 'dm-migrations'

DbFileName = "test.db"

DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, "sqlite:#{DbFileName}")


class Buildopt
  include DataMapper::Resource

  property :id, Serial
  property :opt, String
  #property :opt, String, :unique_index => true

  belongs_to :project
  belongs_to :slave

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
  has n, :buildopt
  #has n, :project
end

class Project
  include DataMapper::Resource

  property :id,     Serial
  property :name,   String, :unique_index => true
  property :url,    String
  property :period, String

  has n, :build
  has n, :buildopt

  def show
    puts "----------------------------------------------------------"
    puts " NAME       : #{@name}"
    puts " URL        : #{@url}"
    puts " Build each : #{@period}"
    puts " Build Options : #{@buildopt_id.class}"
    puts "----------------------------------------------------------"
  end

end

class Build
  include DataMapper::Resource

  property :id,         Serial
  property :start_date, DateTime, :required => true
  property :end_date,   DateTime #, :required => false
  property :result,     Integer #  :required => false

  belongs_to :slave
  belongs_to :project

  def show
    puts "----------------------------------------------------------"
    puts "Build #{@id}"
    puts "----------------------------------------------------------"
    puts "Started on #{@start_date}"
    puts "Ended on #{@end_date}"
    puts "Duration #{@end_date - @start_date}"
    puts "Result #{@result}"
    puts @project_id
    prj = Project.get(@project_id)
    prj.show
    puts @slave_id
#    puts "Build Option #{@slave.buildopt.class}"
#    puts "Build Option #{@project.buildopt.class}"
    puts "----------------------------------------------------------"
  end

end

DataMapper.finalize
DataMapper.auto_upgrade!


prj = Project.first(:name => 'eina')
slv = Slave.first(:name => 'localhost')

if ! prj 
   prj = Project.new( :name => "eina",
                     :url => "svn://svn.enlightenment.org/e/svn/trunk/eina",
                     :period => "24m"
                    )
   prj.save
end

if ! slv
  slv = Slave.new( :name => "localhost",
                  :ip => "127.0.0.1",
                  :user => "toto",
                  :pass => "s3cr3t"
                 )
  slv.save
end



buildopt = Buildopt.create( :opt => "--enable-test", :project => prj, :slave => slv)
buildopt.show

build = Build.create( :start_date => Time.now, :slave => slv, :project => prj )
sleep 2
build.end_date = Time.now
build.result = 0
build.save

builds = Build.all(:slave => slv)
if builds
  builds.each { |el|
    el.show
  }
else
  puts "No builds"
end
