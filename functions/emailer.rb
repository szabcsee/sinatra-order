#!/bin/env ruby
# encoding: utf-8

def emailConfirmOrder(email,file)
  mail = Mail.deliver do
	  to email
	  from 'The Company <order@company-website.com>'
	  subject 'Order'
	  html_part do
	    content_type 'text/html; charset=UTF-8'
	    body '<h1>Dear Customer!</h1>
	    Thank you for your order!
  	<p>You can find your placed order in the attached PDF.</p>

  	Kind Regards: The Company'
	end
	add_file :filename => 'order.pdf', :content => File.read(file)
  end
end