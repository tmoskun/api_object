# Initialize an object from an external API

There is a number of external APIs, which provide data over XML or JSON. For example, BART system API http://api.bart.gov/docs/overview/index.aspx. This gem is to designed to load the external API data into a set of nested Ruby objects. 

## Installation

gem install api_object

## Usage

### Example - BART train departure estimate

1) Subclass your objects from ActiveApi::ApiObject

```
class Departure < ActiveApi::ApiObject
end

class Estimate < ActiveApi::ApiObject
end

class Station < ActiveApi::ApiObject 
end
```
2) Specify the url to load the data from, optionally an action and a mode, an api key and parameters(options) for the url; such as the url would look like "http://\<api_url\>/\<action\>?<mode>&key=\<api_key\>&\<parameter1=value1&parameter2=value2...\>". 

This will be defined in the top object over the function "initialize_from_api". Options for this function:

```
:url - specify url

:action - specify action

:mode - specify mode (such as 'verbose', 'terse' etc.)

:key - api key

:data_tags - specify tag parameters under which object data might be stored, for example <location value='San Francisco'/> - "value" would be a data tag. :data_tags accepts a single value or an array. 

:url_options - parameters
```


The following is designed to generate real time departure estimates for BART stations:

```
class Station

initialize_from_api :url => "http://api.bart.gov/api/", :action => 'etd.aspx', :key => 'MW9S-E7SL-26DU-VV8V', :url_options => {:cmd => 'etd'}

end
```
In this example, the url generated to get real time departure estimates from the Richmond station will be:
http://api.bart.gov/api/etd.aspx?cmd=etd&orig=RICH&key=MW9S-E7SL-26DU-VV8V

3) Define class attributes and mapping of the attributes to the api where the api name is different. To define api simple type mappings, use "api_column \<attribute name\>, \<api attribute name\>". 
To define api association mapping, use "api_association \<association attribute name\>, \<api attribute name\>, :as => \<association class name\>". Either the second, or the third parameters could be omitted. If the third parameter is omitted, the class name will be the same as the attribute name. 

In the following example, a simple attribute name is "abbreviation", but the name defined in the api XML documents is "abbr". An association is defined in the attribute :est, the api mapping is :etd and it's an object of the class Estimate. 

```
class Station < ActiveApi::ApiObject 

initialize_from_api :url => "http://api.bart.gov/api/", :action => 'etd.aspx', :key => 'MW9S-E7SL-26DU-VV8V', :url_options => {:cmd => 'etd'}

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

6) Getting location based data by ip.

A) Getting location using ipinfodb.com (requires api key)

This gem uses [geo_ip gem](https://github.com/jeroenj/geo_ip) and [ipinfodb.com](http://ipinfodb.com/) webservice to retrieve location based on ip. 

The service requires an API key, in order to get it [register](http://ipinfodb.com/register.php) at the web site. 

The [geo_ip gem](https://github.com/jeroenj/geo_ip) retrieves location as:

```
{
  :status_code    => "OK",
  :status_message => "",
  :ip             => "209.85.227.104"
  :country_code   => "US",
  :country_name   => "UNITED STATES",
  :region_name    => "CALIFORNIA",
  :city           => "MONTEREY PARK",
  :zip_code       => "91754",
  :latitude       => "34.0505",
  :longitude      => "-118.13"
}
```

To get the data, call "get_results_by_ip" instead of "get_results":

```
data = Weather.get_results_by_ip('99.156.82.20', :key => <KEY>, :weather => :zip_code)
```

The function takes parameters to define what fields from the location object are passed as what parameter. In this case, "zip_code" field is passed as "weather" parameter and the original function is:

```
data = Weather.get_results(:weather => '99.156.82.20')
```
*This service is allowed to be used only for internal business purposes.* Please, verify with the Terms and Conditions when registering for a key. 


B) Getting location using freegeoip.net (requires no key)

As the ipinfodb.com service has limitations in the terms of use, the gem [freegeoip gem](https://github.com/ezkl/freegeoip) is used whenever no api key is provided. Unfortunatelly, their database last update was April 29, 2011. 

The [freegeoip gem](https://github.com/ezkl/freegeoip) retrieves location as:

```
{
	"city" => "Round Rock"
	"region_code" => "TX"
	"region_name" => "Texas"
	"metrocode" => "635"
	"zipcode" => "78681"
	"longitude" => "-97.7286"
	"latitude" => "30.5321"
	"country_code" => "US"
	"ip" => "99.156.82.20"
	"country_name" => "United States"
}
```
To get the data, call "get_results_by_ip" instead of "get_results":

```
data = Weather.get_results_by_ip('99.156.82.20', :weather => :zipcode)
```

The function takes parameters to define what fields from the location object are passed as what parameter. In this case, "zipcode" field is passed as "weather" parameter and the original function is:

```
data = Weather.get_results(:weather => '99.156.82.20')
```

7) Error handling

In case data cannot be retrived (possible causes might be a wrong url or service downtime), the object returned is empty. Error messages could be checked using functions errors and has_errors?

```
station.has_errors? 
errors = station.errors
```

8) Testing

The gem has been tested on BART, Google Weather and NextBus APIs. 

To run tests by ip location for ipinfodb.com service, please, [register](http://ipinfodb.com/register.php) for an API key.  

The key should be either placed into the test/data/keys/ipinfodb_key.txt file or passed as an environment variable:

```
API_KEY='<your key>' rake test
```

There is no existing api key provided with this gem as per the Terms and Conditions of the ipinfodb service. 

If there is no key provided, those tests will be avoided. 

9) Limitations

* Api data must be presented either in XML or in JSON format. The distinction between XML and JSON is determinted automatically. 
* Location by ip service uses a free database which is not always reliable. 
* When using this gem with external APIs, check Terms and Conditions of the API usage. 
* If something is not working, feel free to submit bugs and or/contribute. 
  
## Compatibility

Ruby 1.9.3

## License

MIT License. Copyright 2012 TJ Moskun.













