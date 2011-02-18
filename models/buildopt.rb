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
