module LoadFromXML
   def load_from_xml xml, root = nil, object_names = []
       result = Nori.parse(xml)
       result = result[root] if root && result.key?(root)
       result.instance_of?(Array) ? result.map {|res| get_object(res, object_names)} : get_object(result, object_names)
   end
   
   def get_object obj, object_names = []
       timestamp = obj["date"].nil? ? {} : {"date" => obj["date"], "time" => obj["time"]}
       [*object_names].each do |o|
         obj = get_next_level(obj, o)
       end
       obj.instance_of?(Array) ? obj.map{|o| new(timestamp.merge(o))} : new(timestamp.merge(obj))
   end
   
   def get_next_level obj, object_name
      if obj.instance_of?(Array)
         return obj.map {|o| o[object_name]} if obj[0].key?(object_name)
      else
         return obj[object_name] if obj.key?(object_name)
      end
      obj
   end
     
end