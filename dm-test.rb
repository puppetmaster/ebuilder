#!/usr/bin/ruby
#

require 'rubygems'
require 'dm-core'
require 'dm-migrations'

DbFileName = "test.db"

DataMapper::Logger.new("debug.out", :debug)
DataMapper.setup(:default, "sqlite:#{DbFileName}")


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
  Slave.create( :name => "sol",
               :ip => "192.168.42.42",
               :user => "john",
               :pass => "Phili"
              )
end


slave = Slave.first(:name => "sol")
begin
  Buildopt.create(:opt => "--test", :slave => slv, :project => prj)
  Buildopt.create(:opt => "--list", :slave => slv, :project => prj)
  Buildopt.create(:opt => "--Grow", :slave => slv, :project => prj)
  Buildopt.create(:opt => "--solaris", :slave => slave, :project => prj)
rescue
  puts "hoho"
end

Buildopt.all.each { |op|
  puts op.opt
}

build = Build.create( :start_date => Time.now, :slave => slv, :project => prj )
sleep 2
build.end_date = Time.now
build.result = 0
build.save

bl = Build.create(:start_date => Time.now, :slave => slave, :project => prj)
bl.end_date = Time.now
bl.result = 1
bl.save

builds = Build.all #(:slave => slv)
if builds
  builds.each { |el|
    el.show
  }
else
  puts "No builds"
end
