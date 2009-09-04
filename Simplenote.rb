#! /usr/bin/ruby
# :title:Simplenote Api wrapper
#
# = Todo
# 0. removing the email/auth token and using cookies (yummi!)
# 0. advanced error handling 
# 0. more documentation
# See {Simplenote} for more details
# = Authors
# Robert Bahmann
#

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
# api = Simplenote.new(user,pwd)
#
# puts "====== Creating a note"
# key = api.createNote("This poor note will be created, updated and than...")
# puts "====== Fetching note"
# pp api.getNote(key)
# puts "====== Updating note"
# api.updateNote(key,"deleted")
# puts "====== fetching it again"
# pp api.getNote(key)
# puts "====== deleting note"
# api.deleteNote(key)
# puts "====== fetching note again"
# pp api.getNote(key)
class Simplenote
  
  #use on agent to provide authentication via cookies (in the future)
  attr_reader :agent
  #token to authenticate against the api
  attr_reader :token
  #login credentials
  attr_reader :email
  attr_reader :password
  def initialize(email,password)
    @agent = Net::HTTP.new('simple-note.appspot.com',443)
    @agent.use_ssl = true
    @email = ERB::Util.url_encode(email)  
    @password = password
    @token = nil
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
  #ToDo: associate timestamp with token to prevent
  #unnecessary authentification
  def refreshToken
    # are we connected?
    if @token.nil?
      @token = getToken(@email,@password)
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


  #Searches for the term and returns by default 10 results.
  # 
  def search(term,maxResults = 10 )
    refreshToken
    url = "/api/search?" + "query=#{ERB::Util.url_encode(term)}\&results=#{maxResults.to_i}\&offset=2\&auth=#{@token}\&email=#{@email}"
    result = agent.get(url,nil)
    return JSON.parse(result.body), JSON.parse(result.body)['responseonse']['totalRecords'].to_i
  end

  #
  def getNote(key)
    refreshToken
    url = "/api/note?key=#{key}&auth=#{@token}\&email=#{@email}&encode=base64"
    response, result = agent.get(url,nil)

     unless response.code.to_i == 200 or result['note-key'].nil?
       raise "Failed to fetch note for \'#{key}\'"
     end
    
    key = response['note-key']
    createDate = response['note-createdate']
    modifyDate = response['note-modifydate']
    deleted = response['note-deleted']
    body = Base64.decode64(result)
    return body,key,createDate,modifyDate,deleted
  end
  
  def createNote(noteText)
    refreshToken
    path = "/api/note?auth=#{@token}\&email=#{@email}&modify=#{ERB::Util.url_encode(Time.now.strftime("%Y-%m-%d %H:%M:%S"))}"
    data = noteText
    payload = Base64.encode64(data)
    response, data = agent.post(path,payload)
    return response.body
  end
  
  def updateNote(key,noteText)
    refreshToken
    path = "/api/note?key=#{key}\&auth=#{@token}\&email=#{@email}&modify=#{ERB::Util.url_encode(Time.now.strftime("%Y-%m-%d %H:%M:%S"))}"
    data = noteText
    payload = Base64.encode64(data)
    response, data = agent.post(path,payload)
    return response.body
  end
  
  def deleteNote(key)
    url = "/api/delete?key=#{key}\&auth=#{@token}\&email=#{@email}"
    agent.get(url,nil)
  end
end

