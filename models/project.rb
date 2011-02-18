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
