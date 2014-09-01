class Order

	include DataMapper::Resource

	property :id, Serial
	property :created_at, DateTime
	property :product_id, Integer
	property :five_ordered, Integer
	property :ten_ordered, Integer
	property :path_to_file, String
  property :wholesaler, String
	belongs_to :client

end