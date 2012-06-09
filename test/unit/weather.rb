require 'api_object'
require_relative 'load_from_xml'
module TestObjects
  
  module WeatherMethods
    def to_s
      inspect
    end
  end
  
  class ForecastInfo < ActiveApi::ApiObject
    include WeatherMethods
    attr_reader :city, :current_date, :current_time
    
    api_column :current_date, :forecast_date
    api_column :current_time, :current_date_time
    
    def inspect
      "#{@city} #{@current_time}"
    end
    
    def ==(other_info)
      return false if other_info.nil?
      self.city == other_info.city
    end
    
  end
  
  class CurrentWeather < ActiveApi::ApiObject
    include WeatherMethods
    attr_reader :sky, :temp_f, :temp_c, :humidity, :wind
    
    api_column :sky, :condition
    api_column :wind, :wind_condition
    
    def inspect
      "Today #{@temp_f}F (#{@temp_c}C), #{@sky}, #{@humidity}, #{@wind}"
    end
  end
  
  class WeatherForecast < ActiveApi::ApiObject
    include WeatherMethods
    attr_reader :day_of_week, :temp_low, :temp_high, :sky
    
    api_column :temp_low, :low
    api_column :temp_high, :high
    api_column :sky, :condition
    
    def inspect
      "#{@day_of_week} low #{@temp_low}, high #{@temp_high}, #{@sky}"
    end
    
    
  end
  
  class Weather < ActiveApi::ApiObject
    extend LoadFromXML
    include WeatherMethods
    attr_reader :forecast_information, :current_conditions, :forecast_conditions
    
    initialize_from_api :url => "http://www.google.com/ig/", :action => 'api', :data_tags => :data
    
    api_association :forecast_information, :as => ForecastInfo
    api_association :current_conditions, :as => CurrentWeather
    api_association :forecast_conditions, :as => WeatherForecast
    
    
    def inspect
      "#{@forecast_information} \n\t#{@current_conditions} \n\t#{@forecast_conditions.instance_of?(Array) ? (@forecast_conditions.inject('') {|str, e| (str + e.inspect + "\n\t")}) : @forecast_conditions}"
    end
    
    def ==(other_weather)
      return false if other_weather.nil?
      self.forecast_information == other_weather.forecast_information && self.current_conditions != nil && other_weather.current_conditions != nil && self.forecast_conditions.size == other_weather.forecast_conditions.size
    end
    
    class << self
      alias_method :general_load_from_xml, :load_from_xml
              
      def load_from_xml xml
        general_load_from_xml(xml, 'xml_api_reply', 'weather')
      end
      
    end
  end
  
  
end