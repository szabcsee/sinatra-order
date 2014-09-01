class Promotion

  include DataMapper::Resource

  property :id, Serial
  property :title, String
  property :description, String, :length => 250
  property :min_discount, Integer
  property :max_discount, Integer
  property :start_date, Date
  property :end_date, Date

end