require 'api_object'
require_relative 'load_from_xml'
module TestObjects
  
  module BusMethods
    def to_s
      inspect
    end
  end
  
  class Stop < ActiveApi::ApiObject
    include BusMethods
    
    attr_reader :tag, :description
    
    api_column :description, :title
    
    def inspect
      "Stop #{@tag}" + (@description.nil? ? '': "- #{@description}")
    end
    
    def ==(other_stop)
      return false if other_stop.nil?
      self.tag == other_stop.tag && self.description == other_stop.description
    end
  
  end
  
  class Direction < ActiveApi::ApiObject
    include BusMethods
    
    attr_reader :tag, :description, :name, :stops
    
    api_column :description, :title
    api_association :stops, :stop, :as => TestObjects::Stop
    
    def inspect
       "Direction #{@tag} - #{@description} \n\t#{@stops.inject('') {|str, s| (str + s.inspect + "\n\t")}}"
    end
    
  end
  
  class Route < ActiveApi::ApiObject
    extend LoadFromXML
    include BusMethods
    
    attr_reader :tag, :description, :stops, :directions
    
    initialize_from_api :url => 'http://webservices.nextbus.com/service', :action => 'publicXMLFeed'
    
    api_column :description, :title
    api_association :stops, :stop, :as => TestObjects::Stop
    api_association :directions, :direction, :as => TestObjects::Direction
    
    def inspect
      "Route #{@tag} - #{@description}" + (@stops.nil? ? '':"\n\t#{@stops.inject('') {|str, s| (str + s.inspect + "\n\t")}}") + (@directions.nil? ? '':"\n\t#{@directions.inject('') {|str, d| (str + d.inspect + "\n\t")}}")
    end
    
    def ==(other_route)
      return false if other_route.nil?
      self.tag == other_route.tag && self.description == other_route.description && self.stops == other_route.stops
    end
    
    class << self
      alias_method :general_load_from_xml, :load_from_xml
              
      def load_from_xml xml
        general_load_from_xml(xml, 'body', 'route')
      end
      
    end
    
  end
  
   
end