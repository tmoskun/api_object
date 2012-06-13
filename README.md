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
2) Specify the url to load the data from, optionally an action and a mode, an api key and parameters(options) for the url; such as the url would look like "http://\<api_url\>/\<action\>?<mode>&key=\<api_key\>&\<parameter1=value1&parameter2=value2...\>". 

This will be defined in the upper object over the function "initialize_from_api". Options for this function:

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
To define api association mapping, use "api_association \<association attribute name\>, \<api attribute name\>, :as => \<association class name\>". Either the second, or the third parameters could be omitted. If the third parameter is omitted, it's mapped to the class name by the attribute name defined in the class. 

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

This gem uses [geo_ip gem](https://github.com/jeroenj/geo_ip) and [ipinfodb.com](http://ipinfodb.com/) webservice to retrieve location based on ip. 

The service requires an API key, in order to get it [register](http://ipinfodb.com/register.php) at the web site. 

Consider making a donation to [ipinfodb.com](http://ipinfodb.com/) at [http://ipinfodb.com/donate.php](http://ipinfodb.com/donate.php).

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

7) Testing

The gem has been tested on BART, Google Weather and NextBus APIs. 

To run test by ip location, please, [register](http://ipinfodb.com/register.php) for an API key.

The key should be either placed into the test/data/keys/ipinfodb_key.txt file or passed as an environment variable:

```
API_KEY='<your key>' rake test
```

There is no existing api key provided with this gem as per the Terms and Conditions of the ipinfodb service. 

8) Limitations

* Api data must be presented either in XML or in JSON format. The distinction between XML and JSON is determinted automatically. 
* When using this gem with external APIs, check Terms and Conditions of the API usage. 
* If something is not working, feel free to submit bugs and or/contribute. 
  
## Compatibility

Ruby 1.9.3

## License

MIT License. Copyright 2012 TJ Moskun.













