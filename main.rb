#! /usr/bin/ruby

require "rubygems"
require 'Simplenote'

api = Simplenote.new(user,pw)

#fetch all notes
 api.index.each{
   |note|
   puts note["key"]
   puts api.getNote(note["key"])[0]
   puts "====================================="
 }