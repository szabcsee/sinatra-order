class Product

	include DataMapper::Resource

	property :id, Serial
	property :name, String
	property :min_orderable_five, Integer
	property :min_orderable_ten, Integer
	property :ordered_five, Integer
	property :ordered_ten, Integer
	property :status, String

end