#!/bin/env ruby
# encoding: utf-8
require 'bundler'
require 'rubygems'
require 'sinatra'
require 'rack-flash'
require 'logger'
require 'csv'
# Database management
require 'pg'
require 'data_mapper'
require 'dm-core'
require 'dm-migrations'
# Mail is for email sending (surprisingly)
require 'mail'
# Prawn is for pdf generation
require "prawn"
require "prawn/measurement_extensions"
# Including helpers
$: << File.dirname(__FILE__) + "/helpers"
require 'helper'
# Including functions
$: << File.dirname(__FILE__) + "/functions"
require 'emailer'
require 'pdf'

# Including models
$: << File.dirname(__FILE__) + "/models"
require 'client'
require 'order'
require 'product'
require 'promotion'

enable :sessions
enable :show_exceptions
use Rack::Flash

APP_ROOT = File.dirname(__FILE__)
set :public_folder, File.dirname(__FILE__) + '/public'



DataMapper.setup(:default, ENV['DATABASE_URL'] || 'postgres://localhost/mydb')
DataMapper::Model.raise_on_save_failure = true

DataMapper.finalize
DataMapper.auto_upgrade!
# Sendgrid implemented for order emails
Mail.defaults do
  delivery_method :smtp, { :address   => "smtp.sendgrid.net",
                           :port      => 587,
                           :domain    => "yourdomain.com",
                           :user_name => "username",
                           :password  => "password",
                           :authentication => 'plain',
                           :enable_starttls_auto => true }
end


get '/' do # Not sure if the Main page will be needed
    @title = "Title before logging in"
    @promotion = Promotion.first()
    erb :index
end

post '/' do
  if params[:reference_number]
    session[:client] = params[:reference_number]
    redirect to("/order-form")
  else
    erb :index
  end
end

get '/order-form' do # Client side order form
  @i = 0
  @products = Product.all(:status => 'active')
  @client = Client.first(:reference => session[:client])
  @promotion = Promotion.first()
  if !@client.nil?
    erb :form
  else
    flash[:warning] = "Unfortunatelly we did not find this customer id"
    redirect to("/")
  end

end


post '/order-form'  do # Process the order form
  @wholesaler = params[:wholesaler]
  @products = Product.all(:status => 'active')
  @promotion = Promotion.first()
  @client = Client.first(:reference => session[:client])
  @min_discount = @client.loyalty == true ? @promotion.min_discount + 5 : @promotion.min_discount
  @max_discount = @client.loyalty == true ? @promotion.max_discount + 5 : @promotion.max_discount
  @all_orders = [["Product name"  ,
                  "Minimum order #{@min_discount}%",
                  "Ordered #{@min_discount}%",
                  "Minimum order #{@max_discount}%",
                  "Ordered #{@max_discount}%"]]

  @filename = @client.reference + '-' + stringified_time
  @path_to_file = "public/forms/#{@filename}.pdf"
  $i = 1
  $z = $i
  until $i == @products.size + 1 do
     $b = $i - 1
      if params[$b.to_s + 'product_five_ordered'] == ""
        @five_ordered = 0
      else
        @five_ordered = params[$b.to_s + 'product_five_ordered'].to_i
      end
      if params[$b.to_s + 'product_ten_ordered'] == ""
        @ten_ordered = 0
        puts "ten_ordered nothing"
      else
        @ten_ordered = params[$b.to_s + 'product_ten_ordered'].to_i
      end
      if ( @five_ordered != 0 && @five_ordered < params[$b.to_s + 'min_orderable_five'].to_i)
        flash[:warning] = "The amount need to reach the minimum ordered items: #{params[$b.to_s + 'product_name']}"
        redirect to("/order-form")
      end
      if (@ten_ordered != 0  && @ten_ordered < params[$b.to_s + 'min_orderable_ten'].to_i)
        flash[:warning] = "The amount need to reach the minimum ordered items: #{params[$b.to_s + 'product_name']}"
        redirect to("/order-form")
      end
           @ordered_item = Order.new(
              :created_at => Time.now,
              :product_id => params[$b.to_s + 'product_id'],
              :five_ordered => @five_ordered,
              :ten_ordered => @ten_ordered,
              :path_to_file => @path_to_file,
              :wholesaler => @wholesaler,
              :client_id => @client.id)
          unless @five_ordered == 0 && @ten_ordered == 0
           min_discount = params[$b.to_s + 'min_orderable_five'] == "0" ? "no discount" : params[$b.to_s + 'min_orderable_five']
           max_discount = params[$b.to_s + 'min_orderable_ten'] == "0" ? "no discount" : params[$b.to_s + 'min_orderable_ten']
           @all_orders[$z] = [params[$b.to_s+'product_name'],
                    min_discount,
                    @ordered_item.five_ordered,
                    max_discount,
                    @ordered_item.ten_ordered]
            $z += 1
           if @ordered_item.save
             puts "Saved successfully"
           else
              @ordered_item.errors.each do |error|
                 puts error
                puts "Didn't save"
              end
           end
        else
          puts @five_ordered
          puts @ten_ordered
        end
    $i += 1
   end
    if render_form(@all_orders, @path_to_file, @client.name, @client.address, @wholesaler)
      puts "Success!"
      emailConfirmOrder(@client.email,@path_to_file)
      flash[:notice] = "Your order has been placed successfully"
      @promotion = Promotion.first()
      erb :order_complete
    else
      flash[:error] = "Unfortunatelly there was a problem with your order."
      redirect to("/order-form")
    end
  end

get '/download/:filename' do
  send_file "public/forms/#{params[:filename]}", :filename => params[:filename], :type => 'Application/pdf'
end



get '/admin' do  #Main admin page
  protected! # This is the helper that authenticates the administrator
  @title = "Administration interface"
  @promotion = Promotion.get(1)
  erb :admin, :layout => :admin_layout
end

get '/admin/clients' do
  protected!
  @title = "Client list"
  @clients = Client.all
  erb :client_list, :layout => :admin_layout
end

post '/admin/clients' do
  protected!
  @clients = Client.all
  @title = "Save new client"
  @client = Client.new(
    :external_id => params[:external_id],
    :name => params[:name],
    :address => params[:address],
    :loyalty => params[:loyalty],
    :email => params[:email],
    :reference => reference_it(params[:name]))
  if @client.save
    flash[:notice] = " #{@client.name} saved"
  end
  redirect to ("/admin/clients")
end

get '/admin/client/:id' do
  protected!
  @client = Client.get(params[:id])
  @title = "#{@client.name} client data"
  erb :client, :layout => :admin_layout
end

get '/admin/clients/edit/:id' do
  protected!
  @client = Client.get(params[:id])
  @title = "#{@client.name} editing"
  erb :client_edit, :layout => :admin_layout
end

post '/admin/clients/edit/:id' do
  protected!
  @client = Client.get(params[:id])
  if @client.update(:external_id => params[:external_id], :name => params[:name], :email => params[:email], :address => params[:address], :loyalty =>params[:loyalty])
    flash[:notice] =  "A #{@client.name} client updated"
  end
  redirect to ("/admin/clients")
end

post '/admin/clients/delete' do
  protected!
  @client = Client.get(params[:id])
  @clients = Client.all
  @title = "#{@client.name} deleted"
  if @client.destroy
    flash[:notice] = "#{@client.name} deleted."
  end
  redirect to ("/admin/clients")
end

#File upload for customers
get '/admin/clients/upload' do
  protected!
  @title = "Upload clients in a CSV format"
  erb :client_upload, :layout => :admin_layout
end

post '/admin/clients/upload' do

  unless params['csvfile'] && (tmpfile = params['csvfile'][:tempfile])
    @notification = "No file selected"
    redirect to ("/admin/clients/upload=#{@notification.to_s}")
  end
  CSV.foreach(tmpfile, encoding: "utf-8") do | row |
    #cid,ordering,email,client name,address1,address2,address3
    unless row[0] == 'cid'
      if row[1] == 'not ordered'
        loyalty = false
      else
        loyalty = true
      end
      reference_number = reference_it(row[3])
      client = Client.first_or_create(
        {:name =>  row[3]},
        {:external_id => row[0], :loyalty => loyalty, :email => row[2], :reference => reference_number, :address => "#{row[4]} #{row[5]} #{row[6]}"}
      )
    end
  end
  flash[:notice] = "Successful upload"
  erb :client_upload, :layout => :admin_layout
end

get '/admin/products' do
  protected!
  @promotion = Promotion.first()
  @title = "Items to order"
  @products = Product.all(:status.not => "deleted")
    erb :product_list, :layout => :admin_layout
end

post '/admin/products' do
  protected!
  @title = "Edit Items"
  @products = Product.all
  @promotion = Promotion.first()
  @updated_product = Product.get(params[:id])
  if @updated_product.update(:status => params[:status])
    flash[:notice] = "The update of the  #{@updated_product.name} was successful."
  end
  redirect to ("/admin/products")
end

post '/admin/products/delete' do
  protected!
  @title = "Delete product"
  @products = Product.all
  @product_to_destroy = Product.get(params[:id])
  if @product_to_destroy.update(:status => "deleted")
    flash[:notice] = "The #{@product_to_destroy.name} has been deleted."
  else
    flash[:notice] = "Error in the operation."
  end
  redirect to ("/admin/products")
end

post '/admin/products/new' do
  protected!
  @title = "New product added"
  if params[:name].empty?
    flash[:warning] = "Add the name of the new product"
    redirect to ("/admin/products")
  end
  params[:min_orderable_five].empty? ? params[:min_orderable_five] = 0 : params[:min_orderable_five]
  params[:min_orderable_ten].empty? ? params[:min_orderable_ten] = 0 : params[:min_orderable_ten]
  @product = Product.new(
    :name => params[:name],
    :min_orderable_five => params[:min_orderable_five],
    :min_orderable_ten => params[:min_orderable_ten],
    :ordered_five => 0,
    :ordered_ten => 0,
    :status => params[:status])
  if @product.save
      flash[:notice] = "The #{@product.name} saved successfully."
  end
  redirect to ("/admin/products")
end

get '/admin/products/edit/:id' do
     protected!
     @promotion = Promotion.first()
     @product = Product.get(params[:id])
     @title = "#{@product.name} edit"
     erb :product_edit, :layout => :admin_layout
end

post '/admin/products/edit/:id' do
      protected!
      @product = Product.get(params[:id])
      @title = "#{@product.name} edit"
      if @product.update(
          :name => params[:name],
          :min_orderable_five => params[:min_orderable_five],
          :min_orderable_ten => params[:min_orderable_ten],
          :ordered_five => 0,
          :ordered_ten => 0,
          :status => params[:status])
        flash[:notice] = "A #{@product.name} was successful."
      end
      redirect to ("/admin/products")
end

get '/admin/orders' do
  protected!
  flash[:notice] =  'Orders can be <a href="/admin/export/client-data">downloaded</a> in CSV format.'
  @title = "Orders"
  @orders = Order.all
  @promotion = Promotion.first()
  @products = Product.all
  @clients = Client.all
  erb :orders, :layout => :admin_layout
end

get '/admin/promotions' do
  protected!
  @title = "Promotions"
  @promotions = Promotion.all
  erb :promotions, :layout =>:admin_layout
end

post '/admin/promotion/new' do
  protected!
  @title = 'Add new promotion'
  if Promotion.get(1).nil?
    @promotion = Promotion.new(
        :title => params[:promo_title],
        :description => params[:promo_desc],
        :min_discount => params[:min_discount],
        :max_discount => params[:max_discount],
        :start_date => params[:start_date],
        :end_date => params[:end_date]
    )
  else
    @promotion = Promotion.get(1)
    @promotion.update(
        :title => params[:promo_title],
        :description => params[:promo_desc],
        :min_discount => params[:min_discount],
        :max_discount => params[:max_discount],
        :start_date => params[:start_date],
        :end_date => params[:end_date]
    )
  end
  if @promotion.save
    flash[:notice] = "A #{@promotion.title} promotion saved successfully"
  end
  redirect to ("/admin")
end

#Export clients data to CSV only called by link. View does not get rendered
get '/admin/export/client-data' do
  protected!
  data = Order.all
  content_type 'application/csv; encoding=utf-8;'
  attachment "orders-export-#{stringified_time()}.csv"
  csv_string = ""
  csv_string = CSV.generate do |csv|
    csv << ["Order date","Product name","min order discount","max order discount","Wholesaler","Client name","External id"]
    data.each do |inv|
      client = Client.get(inv.client_id)
      csv << ["#{inv.created_at.strftime("%d %b %y")}","#{Product.get(inv.product_id) ? Product.get(inv.product_id).name : 'Deleted product'}","#{inv.five_ordered}","#{inv.ten_ordered}","#{inv.wholesaler}","#{client.name}","#{client.external_id}"]
    end
  end
end
