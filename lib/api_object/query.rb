require 'json'
require 'nori'
require 'rest-client'
require_relative 'config_params'

module Query
   include ConfigParams
     
   def  query_api url, command = nil, url_options = {}, options = {} 
     result = nil
     cmd_url = url + (command.nil? ? '':"#{command}?")
     request_url = cmd_url + url_options.to_a.map{|opt| opt[0].to_s + "=" + opt[1]}.join("&")
     Timeout.timeout(self.fallback_timeout) do
       result_raw = RestClient::Request.execute(:method => :get, :url => request_url, :timeout => self.timeout)
       result = result_raw.start_with?('<?xml') ? Nori.parse(result_raw) : JSON.parse(result_raw)
     end
     result
   end
             
end