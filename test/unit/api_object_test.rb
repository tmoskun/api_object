require 'minitest/autorun'
require_relative 'station'
require_relative 'weather'
require_relative 'route'

class ApiObjectTest < MiniTest::Unit::TestCase
  
  include ActiveApi
  include TestObjects
  
  IP = '99.156.82.20'
  GeoIp.api_key = nil 
  
  @@data_directory = File.expand_path('../../data', __FILE__)
  @@estimate_directory = @@data_directory + "/estimate"
  @@weather_directory = @@data_directory + "/weather"
  @@bus_directory = @@data_directory + "/bus"
  @@key_directory = @@data_directory +"/keys"
  

  @@glen_estimate = Station.load_from_xml(File.read(@@estimate_directory + '/glen.xml'))    
  @@sixteenth_estimate = Station.load_from_xml(File.read(@@estimate_directory + '/sixteenth.xml'))
  @@twenty_fourth_estimate = Station.load_from_xml(File.read(@@estimate_directory + '/twenty_fourth.xml'))
  
  @@weather_mv = Weather.load_from_xml(File.read(@@weather_directory + '/mountain_view.xml'))
  @@weather_au = Weather.load_from_xml(File.read(@@weather_directory + '/austin.xml'))
  @@weather_rr = Weather.load_from_xml(File.read(@@weather_directory + '/round_rock.xml'))
  @@ip_key = File.read(@@key_directory + "/ipinfodb_key.txt") rescue ENV['API_KEY']
  
  @@muni_routes = Route.load_from_xml(File.read(@@bus_directory + "/muni_routes.xml"))
  @@muni_F = Route.load_from_xml(File.read(@@bus_directory + "/muni_F.xml"))

  def test_should_get_correct_BART_estimates
    glen_estimate = Station.new(Station.get_results(:orig => 'GLEN'))
    now = DateTime.strptime(glen_estimate.date + " " + glen_estimate.time, "%m/%d/%Y %I:%M:%S %p %Z") 
    if business_time? now
      sixteenth_estimate = Station.new(Station.get_results(:orig => '16TH'))
      twenty_fourth_estimate = Station.new(Station.get_results(:orig => '24TH'))
      assert_equal_station(glen_estimate, @@glen_estimate)
      assert_equal_station(sixteenth_estimate, @@sixteenth_estimate)
      assert_equal_station(twenty_fourth_estimate, @@twenty_fourth_estimate)
    end
  end

  def test_should_not_get_correct_BART_estimates
    glen_estimate = Station.new(Station.get_results(:orig => 'GLEN'))
    now = DateTime.strptime(glen_estimate.date + " " + glen_estimate.time, "%m/%d/%Y %I:%M:%S %p %Z") 
    if business_time? now
      sixteenth_estimate = Station.new(Station.get_results(:orig => '16TH'))
      twenty_fourth_estimate = Station.new(Station.get_results(:orig => '24TH'))
      refute_equal_station(glen_estimate, @@sixteenth_estimate)
      refute_equal_station(sixteenth_estimate, @@twenty_fourth_estimate)
      refute_equal_station(twenty_fourth_estimate, @@glen_estimate)
    end
  end
  
  def test_should_get_correct_weather
    weather_mv = Weather.new(Weather.get_results(:weather => 'Mountain+View'))
    assert_equal(weather_mv, @@weather_mv)
    weather_au = Weather.new(Weather.get_results(:weather => '78744'))
    assert_equal(weather_au, @@weather_au)
  end
  
  
  # Note that the 2 services give slightly different location
  def test_should_get_correct_weather_by_ip_with_no_key
    GeoIp.api_key = nil
    weather_rr = Weather.new(Weather.get_results_by_ip(IP, :key => nil, :weather => :zipcode))
    assert_equal(weather_rr, @@weather_rr)
    refute_has_errors(weather_rr)
  end
   
  def test_should_get_correct_weather_with_key
    unless @@ip_key.nil? 
      weather_au = Weather.new(Weather.get_results_by_ip(IP, :key => @@ip_key, :weather => :zip_code))
      assert_equal(weather_au, @@weather_au)
      refute_has_errors(weather_au)
    end
  end

  def test_should_get_correct_weather_with_key_preset
    unless @@ip_key.nil? 
      GeoIp.api_key = @@ip_key
      weather_au = Weather.new(Weather.get_results_by_ip(IP, :weather => :zip_code))
      assert_equal(weather_au, @@weather_au)
      refute_has_errors(weather_au)
    end
  end
   

  def test_should_get_correct_bus_routes
    routes = Route.get_results(:a => 'sf-muni', :command => 'routeList').map {|r| Route.new(r)}
    assert_equal_route_list(routes, @@muni_routes)
    routes.map {|r| refute_has_errors(r)}
  end

  def test_should_get_correct_route_information
    route_F = Route.new(Route.get_results(:a => 'sf-muni', :command => 'routeConfig', :r => 'F', :mode => 'terse'))
    assert_equal(route_F, @@muni_F)
    refute_has_errors(route_F)
  end

  def test_should_handle_invalid_url
    estimate = Station.new(Station.get_results(:orig => 'YES'))  
    assert(estimate.empty?, "Estimate should be an empty object")
    assert_has_errors(estimate)
    assert(estimate.errors, Station.invalid_url_msg)
    weather = Weather.new(Weather.get_results(:weather => "Here"))
    assert(weather.empty?, "Weather should be an empty object")
    assert_has_errors(weather)
    assert(weather.errors, Weather.invalid_data_msg)
    routes = Route.get_results(:a => 'sffg').collect {|r| Route.new(r)}
    assert(routes.empty?, "Routes should be an empty object")
    assert_has_errors(routes)
    assert(routes.errors, Route.invalid_url_msg)
  end
  

private  
  
  #ensure that the estimates of the first station include the sample
  def assert_equal_station station, sample_station
     if station.instance_of?(Station) && sample_station.instance_of?(Station)
       return assert(station.abbreviation == sample_station.abbreviation && station.est.include_all?(sample_station.est), "Estimates should be equal")
     end
     false
  end
  
  def refute_equal_station station, sample_station
    if station.instance_of?(Station) && sample_station.instance_of?(Station)
       return assert(station.abbreviation != sample_station.abbreviation || station.est.exclude_any?(sample_station.est), "Estimates should be different")
    end
    false
  end
  
  def assert_equal_route_list route_list, sample_route_list
    return assert(route_list.include_all?(sample_route_list), "Route list should include all the sample routes")
  end
  
  def assert_has_errors obj
    return assert(obj.has_errors?, "Object should have errors")
  end
  
  def refute_has_errors obj
    return refute(obj.has_errors?, "Object shouldn't have errors")
  end
  
    
  def business_time? now
    unless now.to_date.sunday? 
         t1 = DateTime.strptime("#{now.month}/#{now.day}/#{now.year} 10:00:00 AM #{now.zone}", "%m/%d/%Y %I:%M:%S %p %:z")
         t2 = DateTime.strptime("#{now.month}/#{now.day}/#{now.year} 08:00:00 PM #{now.zone}", "%m/%d/%Y %I:%M:%S %p %:z")
         return now > t1 && now < t2
    end
    return false
  end
  
  
end

class Array
  def include_all? elems
    return elems.all? {|e| self.include?(e)} if elems.instance_of?(Array)
    false
  end
  
 def exclude_any? elems
   return elems.any? {|e| not self.include?(e) if elems.instance_of?(Array)}
 end
end