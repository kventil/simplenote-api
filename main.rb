#! /usr/bin/ruby

require "rubygems"
require 'Simplenote'

user = "arno@nymo.us"
pwd = "password"

api = Simplenote.new(user,pwd)

puts "====== Creating a note"
key = api.createNote("This poor note will be created, updated and than...")
puts "====== Fetching note"
pp api.getNote(key)
puts "====== Updating note"
api.updateNote(key,"deleted")
puts "====== fetching it again"
pp api.getNote(key)
puts "====== deleting note"
api.deleteNote(key)
puts "====== fetching note again"
pp api.getNote(key)

