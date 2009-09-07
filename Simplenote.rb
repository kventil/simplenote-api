#! /usr/bin/ruby
# :title:Simplenote Api wrapper
#
# = Todo
# 0. removing the email/auth token and using cookies (yummi!)
# 0. advanced error handling 
# 0. more documentation
# See Simplenote for more details
# 
# Author::    Robert Bahmann  (mailto:robert.bahmann@gmail.com)
# License::   Distributes under the same terms as Ruby


require "rubygems"
require "net/https"
require "net/http"
require "erb"
require "base64"
require "logger"
require "uri"
require "pp"
require "json"

#Simple wrapper for the API provided by the guys from simplenote.
#(http://www.simplenoteapp.com/index.html)
#= Example
# require 'Simplenote'
# #creating the obj with user and password
# api = Simplenote.new(email,password)
#
# #creating a note and saving its key
# key = api.createNote("This poor note will be created, updated and than...")
# #fetching the same note via key
# pp api.getNote(key)
# #updating the note with a new string 
# api.updateNote(key,"deleted")
# #fetching it again to look if it's updated ;-)
# pp api.getNote(key)
# #delete the note
# api.deleteNote(key)
# #and trying to fetch it again. Have a look at the "deleted" flag (the last one which is now true)
# pp api.getNote(key)
class Simplenote
  
  #use on agent to provide authentication via cookies (in the future)
  attr_reader :agent
  #token to authenticate against the api
  attr_reader :token
  #timestamp to determine the tokens age
  attr_reader :tokenTimeStamp
  #login credentials
  attr_reader :email
  attr_reader :password
  def initialize(email,password)
    @agent = Net::HTTP.new('simple-note.appspot.com',443)
    @agent.use_ssl = true
    @email = ERB::Util.url_encode(email)  
    @password = password
    @token = nil
    @tokenTimeStamp = nil
  end
  
  
  private
  #Authenticate and fetch token
  def getToken(email,password)
     path = '/api/login'
     data = "email=#{@email}&password=#{ERB::Util.url_encode(password)}" 
     payload = Base64.encode64(data)
     puts payload
     
     response, data = agent.post(path,payload)
     
     unless response.code.to_i == 200
       raise "Failed to fetch token for #{email}"
     end
     return data.strip.to_s
  end
  
  #Checks if we have a valid token
  def refreshToken
    # is there a token? (and is it's timestamp not older than 24h?)
    if @token.nil? or @tokenTimeStamp < Time.now - 86400
      @token = getToken(@email,@password)
      @tokenTimeStamp = Time.now
    end
  end
  
  public
  #Gets an index of all notes and returns it as an json-obj
  # 
  #Sample response:
  # [
  #   { "key": "notekey1", "modify": "2008-11-30 14:10:40.123456","deleted": false },
  #   { "key": "notekey1", "modify": "2008-11-30 14:10:40.123456","deleted": true }
  # ]
  #Notes marked as "deleted" will be removed at next sync with iPhone
  # 
  def index()
    refreshToken
    url = "/api/index?auth=#{@token}\&email=#{@email}"
    result = agent.get(url,nil)
    return JSON.parse(result.body)
  end


  #Searches for the term and returns by default 10 results
  #as a json db
  def search(term,maxResults = 10 )
    refreshToken
    url = "/api/search?" + "query=#{ERB::Util.url_encode(term)}\&results=#{maxResults.to_i}\&offset=2\&auth=#{@token}\&email=#{@email}"
    result = agent.get(url,nil)
    return JSON.parse(result.body), JSON.parse(result.body)['responseonse']['totalRecords'].to_i
  end

  #fetches note via key and returns an array:
  # [text,key,createdate,modifyDate,deleted]
  def getNote(key)
    refreshToken
    url = "/api/note?key=#{key}&auth=#{@token}\&email=#{@email}&encode=base64"
    response, result = agent.get(url,nil)
    
     unless response.code.to_i == 200
       raise "Failed to fetch note for \'#{key}\'"
     end
    
    key = response['note-key']
    createDate = response['note-createdate']
    modifyDate = response['note-modifydate']
    deleted = response['note-deleted']
    body = Base64.decode64(result)
    return body,key,createDate,modifyDate,deleted
  end
  
  #creates a new note and returns it's associated key
  def createNote(noteText)
    refreshToken
    path = "/api/note?auth=#{@token}\&email=#{@email}&modify=#{ERB::Util.url_encode(Time.now.strftime("%Y-%m-%d %H:%M:%S"))}"
    data = noteText
    payload = Base64.encode64(data)
    response, data = agent.post(path,payload)
    unless response.code.to_i == 200
      raise "Failed to create new note"
    end
    return response.body
  end
  
  #Updates note with given noteText and returns 
  def updateNote(key,noteText)
    refreshToken
    path = "/api/note?key=#{key}\&auth=#{@token}\&email=#{@email}&modify=#{ERB::Util.url_encode(Time.now.strftime("%Y-%m-%d %H:%M:%S"))}"
    data = noteText
    payload = Base64.encode64(data)
    response, data = agent.post(path,payload)
    
    unless response.code.to_i == 200
      raise "Failed to update Note \'#{key}\'"
    end
    return response.body
  end
  
  def deleteNote(key)
    url = "/api/delete?key=#{key}\&auth=#{@token}\&email=#{@email}"
    agent.get(url,nil)
  end
end

