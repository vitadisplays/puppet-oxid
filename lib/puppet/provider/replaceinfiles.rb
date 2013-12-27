Puppet::Type.type(:replaceinfiles).provide(:posix) do
    desc "Replace token in a text file"

    def create    			
    	text = File.read(@resource[:name])			
	
		@resource[:tokens].each do |key,value| 
			replace = text.gsub(key, value)	
		end
		  		
  		File.open(@resource[:name], "w") { |file| file.puts replace }
    end

    def destroy
        File.unlink(@resource[:name])
    end

    def exists?
        File.exists?(@resource[:name])
    end
end