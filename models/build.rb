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

end
