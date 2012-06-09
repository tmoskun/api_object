require 'json'
require 'nori'
require 'rest-client'
require_relative 'config_params'

module Query
   include ConfigParams
     
   def query_api url, action = nil, mode = nil, url_options = {}, options = {} 
     result = nil
     request_url = get_url(url, action, mode, url_options)
     Timeout.timeout(self.fallback_timeout) do
       result_raw = RestClient::Request.execute(:method => :get, :url => request_url, :timeout => self.timeout)
       result = result_raw.start_with?('<?xml') ? Nori.parse(result_raw) : JSON.parse(result_raw)
     end
     {:result => result, :success => !result.nil?, :url => request_url}
   end
   
   def get_url url, action = nil, mode = nil, url_options = {}
     cmd_url = url.chomp("/") + "/" + (action.nil? ? '':"#{action}?") # url + action
     cmd_url + (mode.nil? ? '' : "#{mode}&") + url_options.to_a.map{|opt| opt[0].to_s + "=" + opt[1]}.join("&") # add parameters
   end
             
end