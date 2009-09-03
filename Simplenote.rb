#! /usr/bin/ruby

require "rubygems"
require "net/https"
require "net/http"
require "erb"
require "base64"
require "logger"
require "uri"
require "pp"
require "json"

$LOG = Logger.new('api.log')
$LOG.level = Logger::DEBUG

class Simplenote
  
  attr_reader :agent
  attr_reader :token
  attr_reader :email
  
  def initialize(email,password)
    @agent = Net::HTTP.new('simple-note.appspot.com',443)
    @agent.use_ssl = true
    @email = ERB::Util.url_encode(email)  
    @token = getToken(email,password)
  end
  
  private
  def getToken(email,password)
    $LOG.info("Fetching token for #{email}")
     path = '/api/login'
     data = "email=#{@email}&password=#{ERB::Util.url_encode(password)}" 
     payload = Base64.encode64(data)
     puts payload
     
     response, data = agent.post(path,payload)
     
     unless response.code.to_i == 200
       $LOG.error("Failed to fetch token for #{email}")
       raise "Failed to fetch token for #{email}"
     end
      $LOG.info("Fetched token: #{data}")
     return data.strip.to_s
  end
  
  public
  
  def index()
    $LOG.info("Fetching index")
    url = "/api/index?auth=#{@token}\&email=#{@email}"
    result = agent.get(url,nil)
    return JSON.parse(result.body)
  end

  def search(term,maxResults)
    $LOG.info("Searching for \'#{term}\'")
    url = "/api/search?" + "query=#{ERB::Util.url_encode(term)}\&results=#{maxResults.to_i}\&offset=2\&auth=#{@token}\&email=#{@email}"
    result = agent.get(url,nil)
    return JSON.parse(result.body), JSON.parse(result.body)['responseonse']['totalRecords'].to_i
  end

  def getNote(key)
    $LOG.info("Fetching Note #{key}")
    
    url = "/api/note?key=#{key}&auth=#{@token}\&email=#{@email}&encode=base64"
    response, result = agent.get(url,nil)

     unless response.code.to_i == 200 or result['note-key'].nil?
       $LOG.error("Failed to fetch note for \'#{key}\'")
       raise "Failed to fetch note for \'#{key}\'"
     end
    
    $LOG.info("Fetched node: #{key}")
    
    key = response['note-key']
    $LOG.debug("key: " + key)
    createDate = response['note-createdate']
    $LOG.debug("createDate: " +  createDate)
    modifyDate = response['note-modifydate']
    $LOG.debug("modifyDate: " + modifyDate)
    deleted = response['note-deleted'].eql?("true")
    $LOG.debug("deleted: " + deleted.to_s)
    body = Base64.decode64(result)
    $LOG.debug("body: " + body)
    return body,key,createDate,modifyDate,deleted
  end
end

