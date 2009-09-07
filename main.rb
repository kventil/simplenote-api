#! /usr/bin/ruby

require "rubygems"
require 'Simplenote'

email = "email"
pwd = "password"

api = Simplenote.new(email,pwd)

puts  Time.now - 86400

puts "====== Creating a note"
key = api.createNote("This poor note will be created, updated and than...")
puts "====== Fetching note"
pp api.getNote(key)
puts "====== Updating note"
pp api.updateNote(key,"deleted")
puts "====== fetching it again"
pp api.getNote(key)
puts "====== deleting note"
api.deleteNote(key)
puts "====== fetching note again"
pp api.getNote(key)

