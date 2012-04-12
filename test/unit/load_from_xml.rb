module LoadFromXML
   def load_from_xml xml
       hash = Nori.parse(xml)
       hash = hash["root"] if hash.keys.include?("root")
       timestamp = hash["date"].nil? ? {} : {"date" => hash["date"], "time" => hash["time"]}
       hash = hash["stations"] if hash.keys.include?("stations")
       hash = hash["station"] if hash.keys.include?("station")
       new(timestamp.merge(hash))
   end
end