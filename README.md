# Initialize an object from an external API

There is a number of external APIs, which provide data over XML or JSON. For example, BART system API http://api.bart.gov/docs/overview/index.aspx. This gem is to designed to load the external API data into a set of nested Ruby objects. 

## Installation

gem install api_object

## Usage

### Example - BART train departure estimate

1) Subclass your objects from ActiveApi::ApiObject

```
class Station < ActiveApi::ApiObject
end

class Estimate < ActiveApi::ApiObject
end

class Station < ActiveApi::ApiObject 
end
```
2) Specify the url to load the data from, optionally a command, an api key and parameters(options) for the url; such as the url would look like "http://\<api_url\>/\<command\>?key=\<api_key\>&\<parameter1=value1&parameter2=value2...\>". 

This will be defined in the upper object over the function "initialize_from_api". Options for this function:

```
:url - specify url

:command - specify command

:key - api key

:url_options - parameters
```


The following is designed to generate real time departure estimates for BART stations:

```
class Station

initialize_from_api :url => "http://api.bart.gov/api/", :command => 'etd.aspx', :key => 'MW9S-E7SL-26DU-VV8V', :url_options => {:cmd => 'etd'}

end
```
In this example, the url generated to get real time departure estimates from the Richmond station will be:
http://api.bart.gov/api/etd.aspx?cmd=etd&orig=RICH&key=MW9S-E7SL-26DU-VV8V

3) Define class attributes and mapping of the attributes to the api where the api name is different. To define api simple type mappings, use "api_column \<attribute name\>, \<api attribute name\>". 
To define api association mapping, use "api_association \<association attribute name\>, \<api attribute name\>, :as => \<association class name\>". Either the second, or the third parameters could be omitted. If the third parameter is omitted, it's mapped to the class name by the attribute name defined in the class. 

In the following example, a simple attribute name is "abbreviation", but the name defined in the api XML documents is "abbr". An association is defined in the attribute :est, the api mapping is :etd and it's an object of the class Estimate. 

```
class Station < ActiveApi::ApiObject 

initialize_from_api :url => "http://api.bart.gov/api/", :command => 'etd.aspx', :key => 'MW9S-E7SL-26DU-VV8V', :url_options => {:cmd => 'etd'}

attr_reader :name, :abbreviation, :date, :time, :est

api_column :abbreviation, :abbr
api_association :est, :etd, :as => Estimate

end
```
4) To load api data into an object, use the class method "get_results(options)". In the example, get real time estimates for the station Glen Park. 

```
data = Station.get_results(:orig => 'GLEN')
```

Please, note that data loaded might be either a hash, or an array of hashes, depending on the api.

5) Create an object from the data

If the example, the data received is a hash, so create an object. 

```
station = Station.new(data)
```

If the data is an array of hashes, then it might be used to create an array of objects

```
stations = data.map {|d| Station.new(d)}
```

6) Limitations
  * Api data must be presented either in XML or in JSON format. The distinction between XML and JSON is determinted automatically. 
  * This is still a very early version and needs more testing. If something is not working, feel free to submit bugs and or/contribute. 
  
## Compatibility

Ruby 1.9.3

## License

MIT License. Copyright 2012 TJ Moskun.













