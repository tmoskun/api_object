require 'minitest/autorun'
require_relative 'station'

class ApiObjectTest < MiniTest::Unit::TestCase
  
  include ActiveApi
  include TestObjects

  @@data_directory = File.expand_path('../../data', __FILE__)
  @@estimate_directory = @@data_directory + "/estimate"
   
  @@glen_estimate = Station.load_from_xml(File.read(@@estimate_directory + '/glen.xml'))    
  @@sixteenth_estimate = Station.load_from_xml(File.read(@@estimate_directory + '/sixteenth.xml'))
  @@twenty_fourth_estimate = Station.load_from_xml(File.read(@@estimate_directory + '/twenty_fourth.xml'))
    
  def test_should_get_correct_estimates
    glen_estimate = Station.new(Station.get_results(:orig => 'GLEN'))
    now = DateTime.strptime(glen_estimate.date + " " + glen_estimate.time, "%m/%d/%Y %I:%M:%S %p %Z") 
    if business_time? now
      sixteenth_estimate = Station.new(Station.get_results(:orig => '16TH'))
      twenty_fourth_estimate = Station.new(Station.get_results(:orig => '24TH'))
      assert_equal(glen_estimate, @@glen_estimate)
      assert_equal(sixteenth_estimate, @@sixteenth_estimate)
      assert_equal(twenty_fourth_estimate, @@twenty_fourth_estimate)
    end
  end
  
    
private 
  def business_time? now
    unless now.to_date.sunday? 
         #t = now.to_time.localtime(now.zone)
         #t1 = DateTime.strptime("#{now.month}/#{now.day}/#{now.year} 10:00:00 AM #{now.zone}", "%m/%d/%Y %I:%M:%S %p %:z").to_time.localtime(now.zone)
         #t2 = DateTime.strptime("#{now.month}/#{now.day}/#{now.year} 08:00:00 PM #{now.zone}", "%m/%d/%Y %I:%M:%S %p %:z").to_time.localtime(now.zone)
         t1 = DateTime.strptime("#{now.month}/#{now.day}/#{now.year} 10:00:00 AM #{now.zone}", "%m/%d/%Y %I:%M:%S %p %:z")
         t2 = DateTime.strptime("#{now.month}/#{now.day}/#{now.year} 08:00:00 PM #{now.zone}", "%m/%d/%Y %I:%M:%S %p %:z")
         return now > t1 && now < t2
    end
    return false
  end
  
end