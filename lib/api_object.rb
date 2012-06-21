require "api_object/version"
require "api_object/query"
require "active_support/all"
require "geo_ip"
require 'freegeoip'

module ActiveApi
        
    module ClassMethods 
          
      def self.extended(base)
        base.send(:extend, Query)     
      end
              
      def initialize_from_api options = {}
        
          class_attribute :url, :action, :key, :mode, :url_options, :data_tags, :object_name
          self.url, self.action, self.key, self.mode, self.url_options, self.data_tags, self.object_name = [options[:url], options[:action], options[:key], options[:mode], (options[:url_options] || {}), ([*options[:data_tags]] || []), (options[:object_name] || self.to_s.downcase.gsub(/^(.+::)(.+)$/, '\2'))]
          instance_eval do
            
          
             def get_results_by_ip ip, arguments = {}
                self.api_key = arguments.delete(:key) if arguments.include?(:key)
                if self.api_key
                  location = GeoIp.geolocation(ip)
                  raise unless location[:status_code] == "OK"
                  return get_results [*arguments.keys].inject({}) { |opts, a| opts.merge(a.to_sym => location[arguments[a.to_sym]]) }
                else
                  location = FreeGeoIP.locate(ip)
                  get_results [*arguments.keys].inject({}) { |opts, a| opts.merge(a.to_sym => location[arguments[a.to_sym].to_s]) }
                end
                rescue
                  puts "ERROR: Cannot get results or location by ip. Verify that you have a valid key for the location service"
                 return ApiObjectError.new(:class => self, :errors => invalid_loc_msg)
             end
          
             def get_results options = {}
               self.url_options.merge!(:key => self.key) unless self.key.nil?
               [:url, :action, :mode].each {|opt| eval("self.#{opt.to_s} = options.delete(opt)") if options[opt]}
               result = query_api(self.url, self.action, self.mode, self.url_options.merge(options))
               process_result result
               rescue
                 puts "ERROR: The request returned no valid data. #{error_invalid_url result[:url]}"
                 return ApiObjectError.new(:class => self, :errors => invalid_url_msg)
             end 
             
             def api_key=(key)
                GeoIp.api_key = key
             end
             
             def api_key
                GeoIp.api_key
             end
                       
             def error_invalid_url url
               "The request url is #{url}, please, check if it's invalid of there is no connectivity." unless url.nil?
             end
             
             def invalid_url_msg
               "Cannot get results from the url"
             end
             
             def invalid_loc_msg
               "Cannot obtain results by ip, check the location"
             end
             
             def invalid_data_msg
               "Cannot initialize the object"
             end
                                          
             private
             def process_result result
               raise unless result[:success]
               
               obj = result[:result]
               url = result[:url]
               other_keys = {}
               until obj.keys.include?(self.object_name.to_s)
                  obj = obj[obj.keys[0]]
                  other_keys.merge!(obj.keys.inject({}) { |h, k| (self.method_defined?(k) ? h.merge(k => obj[k]) : h)})    
               end
               res = obj[self.object_name.to_s]
               res.instance_of?(Array) ? res.map{|r| attach_url other_keys.merge(r), url} : (attach_url other_keys.merge(res), url)              
             end 
                        
             
             def attach_url result, url
                result.merge(:url => url)
             end
                                  
          end
      end
                   
   end
   
   module InstanceMethods
                
      def initialize(*args)
          url = args.first.delete(:url)
          errors = args.first.delete(:errors)
          tags = respond_to?('data_tags') ? self.data_tags : args.last[:tags]
          args.first.each do |k, v| 
             k = k.gsub(/@/, '')
             k = self.columns[k.to_sym] unless self.columns[k.to_sym].nil?
             if self.respond_to?(k)   # check if it's included as a class attribute
                klass = self.assoc[k.to_sym] || k
                result = v.instance_of?(Array) ? v.map {|v1| init_object(v1, klass, tags)} : init_object(v, klass, tags)
                instance_variable_set("@#{k.to_s}", result)
             end
          end if args.first.is_a?(Hash)
          if self.empty?
            puts "ERROR: data passed for #{self.class} initialization was invalid. #{self.class.error_invalid_url url}" 
            @errors = errors || self.class.invalid_data_msg
          end
      end
      
      def empty?
          (self.instance_variables - [:@errors]).empty?
      end
      
      def has_errors?
        self.instance_variables.include?(:@errors)
      end
            
            
      def persisted?
          false
      end
               
    private    
                      
      def init_object value, klass, tags = []
          if value.instance_of?(Hash)
            if value.size == 1 && tags.include?(value.keys[0].gsub(/@/,'').to_sym)
              value.values[0]
            else
              klass = (get_module_name + klass.to_s.gsub(/@/,'').capitalize).constantize unless klass.class == Class
              klass.new(value, {:tags => tags})
            end
          else
            value
          end
      end
      
      def get_module_name
          (self.class.name =~ /^(.+::).+$/) ? $1 : ''
      end
            
    end
    
    module SingletonMethods
      def api_column column_name, api_name
         self.columns.merge!(api_name => column_name)
      end
           
      def api_association (*args)
         options = args.extract_options!
         self.columns.merge!(args[1] => args[0]) if args.length >= 2
         self.assoc.merge!(args[0] => options[:as]) unless options[:as].nil? 
      end 
          
         
    end 
    
    class ApiObject
        extend ClassMethods
        include InstanceMethods
        extend SingletonMethods
                    
       class_attribute :columns, :assoc 
       self.columns, self.assoc = [{}, {}]
       
       attr_reader :errors
       
    end 
    
    class ApiObjectError < Hash
        attr_reader :errors, :klass
        
        def initialize *args
          options = args.extract_options!
          @errors = options.delete(:errors)
          @klass = options.delete(:class)
        end
                
        def keys
          [:errors]
        end
        
        def [](key)
          eval("self.#{key.to_s}") if keys.include?(key)
        end
        
        def map &block
          klass.new({:errors => @errors})
        end
        
        alias_method :collect, :map
        
        def inspect
          "ApiObjectError: #{@errors}"
        end
        
        def to_s
          inspect
        end
    end 
       
  end
          