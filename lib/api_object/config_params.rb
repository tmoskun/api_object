module ConfigParams
    
     IPV4_REGEXP = /\A(?:25[0-5]|(?:2[0-4]|1\d|[1-9])?\d)(?:\.(?:25[0-5]|(?:2[0-4]|1\d|[1-9])?\d)){3}\z/
     TIMEOUT = 3
     FALLBACK_TIMEOUT = 3
      
     def timeout
        TIMEOUT
     end
  
     def timeout= timeout
        self.TIMEOUT = timeout
     end
    
     def fallback_timeout
        FALLBACK_TIMEOUT
     end
    
     def fallback_timeout= fallback_timeout
        self.FALLBACK_TIMEOUT = fallback_timeout
     end
        
end    