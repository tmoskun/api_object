require "api_object/version"
require "api_object/query"
require "active_support/all"

module ActiveApi
      
    module ClassMethods 
    
      def self.extended(base)
        base.send(:extend, Query)     
      end
              
      def initialize_from_api options = {}
          class_attribute :url, :action, :key, :mode, :url_options, :data_tags, :object_name
          self.url, self.action, self.key, self.mode, self.url_options, self.data_tags, self.object_name = [options[:url], options[:action], options[:key], options[:mode], (options[:url_options] || {}), ([*options[:data_tags]] || []), (options[:object_name] || self.to_s.downcase.gsub(/^(.+::)(.+)$/, '\2'))]
          instance_eval do
          
             def get_results options = {}
               self.url_options.merge!(:key => self.key) unless self.key.nil?
               [:url, :action, :mode].each {|opt| eval("self.#{opt.to_s} = options.delete(opt)") if options[opt]}
               result = query_api(self.url, self.action, self.mode, self.url_options.merge(options))
               process_result result
               rescue
                 puts "WARNING: The request returned no valid data. #{warning_invalid_url result[:url]}"
                 return {}
             end 
             
             def warning_invalid_url url
               "The request url is #{url}, please, check if it's invalid of there is no connectivity." unless url.nil?
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
          puts "WARNING: data passed for #{self.class} initialization was invalid. #{self.class.warning_invalid_url url}" if self.empty?
      end
      
      def empty?
          self.instance_variables.empty?
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
       
    end
    
      
  end
             