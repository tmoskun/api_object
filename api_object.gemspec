# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "api_object/version"

Gem::Specification.new do |s|
  s.name        = "api_object"
  s.version     = ApiObject::VERSION
  s.authors     = ["tmoskun"]
  s.email       = ["tanyamoskun@gmail.com"]
  s.homepage    = "https://github.com/tmoskun/api_object"
  s.summary     = %q{An interface to load objects from external APIs provided in XML and JSON formats}
  s.description = %q{An interface to load objects from external APIs provided in XML and JSON formats}

  s.rubyforge_project = "api_object"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
  
  #s.add_development_dependency "sqlite3"
  s.add_development_dependency "activemodel"
  s.add_development_dependency "rspec"
  s.add_development_dependency "minitest"
  s.add_dependency "activesupport"
  s.add_dependency('nori', '>=1.1')
  s.add_dependency('rest-client', '>= 1.6')
  s.add_dependency 'geo_ip'
  
end
