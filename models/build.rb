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
