helpers do
  def protected!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized\n"
  end

  def base_url
    @base_url ||= "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    # Hard coded admin password
    @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == ['admin', 'password']
  end
  def stringified_time
    time = Time.now
    return time.year.to_s + time.month.to_s + time.day.to_s + time.hour.to_s + time.min.to_s
  end
  #Produces a 6 digit numeric string
  def random_numeric(size)
    random_number = size.times.map{ 1 + Random.rand(9)}
    random_number = random_number.to_s
    random_number = random_number.gsub(' ','').gsub('[','').gsub(']','').gsub('"','').gsub(',','')
    return random_number
  end

  #Gets a string as a name to create reference number
  def reference_it(value)
   reference_number = value[0,2].to_s.downcase
   reference_number += value.reverse[0,1].to_s.downcase
   reference_number += random_numeric(6)
   return reference_number
  end
end