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
