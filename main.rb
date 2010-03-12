#! /usr/local/bin/ruby
require 'Simplenote'


#creating the obj with user and password
api = Simplenote.new(email,password)

#creating a note and saving its key
key = api.create("This poor note will be created, updated and than...")
#fetching the same note via key
pp api.get(key)
#updating the note with a new string 
api.update(key,"deleted")
#fetching it again to look if it's updated ;-)
pp api.get(key)
#delete the note
api.delete(key)
#and trying to fetch it again. Have a look at the "deleted" flag (the last one which is now true)
#this note will be deleted at the next sync with the iPhone app
pp api.get(key)         