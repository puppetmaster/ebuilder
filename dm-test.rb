#!/usr/bin/ruby
#

require 'rubygems'
require 'dm-core'
require 'dm-migrations'

DbFileName = "test.db"

DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, "sqlite:#{DbFileName}")


class Slave
  include DataMapper::Resource

#  property :id,   Serial
  property :name, String, :key => true
  property :ip,   String
  property :user, String
  property :pass, String

  has n, :build
  #has n, :project
end

class Project
  include DataMapper::Resource

#  property :id,     Serial
  property :name,   String, :key => true
  property :url,    String
  property :period, String

  has n, :build
  #has n, :slave
  #
  
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
    puts "----------------------------------------------------------"
  end

end

if ! File.exist?(DbFileName)
  DataMapper.finalize
  DataMapper.auto_migrate!
  DataMapper.auto_upgrade!

  Project.create( :name => "eina",
                 :url => "svn://svn.enlightenment.org/e/svn/trunk/eina",
                 :period => "24m"
                )

  Slave.create( :name => "localhost",
                :ip => "127.0.0.1",
                :user => "toto",
                :pass => "s3cr3t"
               )

  slv = Slave.get('localhost')
  prj = Project.get('eina')

  3.times do 
    build = Build.create( :start_date => Time.now, :slave => slv, :project => prj )
    sleep 2
    build.end_date = Time.now
    build.result = 0
    build.save
  end
end


slv = Slave.get('localhost')
prj = Project.get('eina')


prj.show

builds = Build.all(:slave => slv)
builds.each { |el|
  el.show
}
