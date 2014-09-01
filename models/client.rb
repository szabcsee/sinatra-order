class Client

	include DataMapper::Resource
	property :id, Serial
  	property :external_id, String
	property :email, String
	property :name, String
	property :address, String
  	property :loyalty, Boolean
	property :reference, String
	has n, :orders

end