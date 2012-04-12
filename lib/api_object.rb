require "api_object/version"
require "api_object/query"
require "active_support/all"

module ActiveApi
       
    module ClassMethods 
      
      def self.extended(base)
        base.send(:extend, Query)     
      end
              
      def initialize_from_api options = {}
          class_attribute :url, :command, :key, :url_options, :object_name
          self.url, self.command, self.key, self.url_options, self.object_name = [options[:url], options[:command], options[:key], (options[:url_options] || {}), (options[:object_name] || self.to_s.downcase.gsub(/^(.+::)(.+)$/, '\2'))]
      end
            
      def get_results options = {}
          self.url_options.merge!(:key => self.key) unless self.key.nil?
          result = query_api(self.url, self.command, self.url_options.merge(options))
          other_keys = {}
          unless result.nil? 
            until result.keys.include?(self.object_name.to_s)
               result = result[result.keys[0]]
               return nil if (result.nil? || result.empty? || result.instance_of?(Array)) 
               other_keys.merge!(result.keys.inject({}) { |h, k| (self.method_defined?(k) ? h.merge(k => result[k]) : h)})    
            end
          end
          other_keys.merge(result[self.object_name.to_s])
      end
      
   end
   
   module InstanceMethods
            
      def initialize(*args)
          args.first.each do |k, v| 
             unless defined?(k).nil?    # check if it's included as a reader attribute
                k = self.columns[k.to_sym] unless self.columns[k.to_sym].nil?
                klass = self.assoc[k.to_sym] || k
                result = v.instance_of?(Array) ? v.inject([]) {|arr, v1| arr << init_object(v1, klass)} : init_object(v, klass)
                instance_variable_set("@#{k.to_s}", result)
             end
          end if (args.length == 1 && args.first.is_a?(Hash)) 
      end
            
            
      def persisted?
          false
      end
      
       
    private    
                      
      def init_object value, klass
          if value.instance_of?(Hash)
            klass = (get_module_name + klass.to_s.capitalize).constantize unless klass.class == Class
            klass.new(value)
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
             