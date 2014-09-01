require 'rubygems'
require 'sinatra'
require File.expand_path '../app.rb', __FILE__

NewRelic::Agent.after_fork(:force_reconnect => true)

run Sinatra::Application