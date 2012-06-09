require 'api_object'
require_relative 'load_from_xml'
module TestObjects
  
  module StationMethods
     def to_s
       inspect
     end
      
  end
  
  class Departure < ActiveApi::ApiObject
      include StationMethods
      attr_reader :minutes, :platform, :direction, :length, :color, :bikes_allowed
      
      api_column :bikes_allowed, :bikeflag
   
      def inspect
         "#{@platform} platform - #{@minutes}#{(@minutes == 'Leaving') ? '':' minutes'}"
      end
  
      def ==(other_)
        true
      end
      
  end
  
  class Estimate < ActiveApi::ApiObject
      include StationMethods
      attr_reader :abbreviation, :destination, :estimate
      
      api_association :estimate, :as => Departure
     
      def inspect
         "destination #{@destination} \n\t\t #{@estimate.inspect}"
      end
      
      def ==(other_est)
        return false if other_est.nil?
        self.abbreviation == other_est.abbreviation && self.destination == other_est.destination
      end
      
  end
  
  class Station < ActiveApi::ApiObject 
      extend LoadFromXML
      include StationMethods
      
      attr_reader :name, :abbreviation, :date, :time, :est
        
      initialize_from_api :url => "http://api.bart.gov/api/", :action => 'etd.aspx', :key => 'MW9S-E7SL-26DU-VV8V', :url_options => {:cmd => 'etd'}
         
      api_column :abbreviation, :abbr
      api_association :est, :etd, :as => TestObjects::Estimate
      
      def inspect
         "#{@name} at #{@date}, #{@time} \n\t #{@est.instance_of?(Array) ? (@est.inject('') {|str, e| (str + e.inspect + "\n\t")}) : @est}"
      end
      
      def ==(other_station)
        return false if other_station.nil?
        self.abbreviation == other_station.abbreviation && self.est == other_station.est
      end
      
      class << self
        alias_method :general_load_from_xml, :load_from_xml
              
        def load_from_xml xml
          general_load_from_xml(xml, 'root', ['stations', 'station'])
        end
      
      end
               
    end
    
end