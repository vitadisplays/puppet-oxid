require 'mkmf'

module Puppet::Parser::Functions
    newfunction(:php_version, :type => :rvalue) do |args|
    	result = ""    	

		if find_executable 'php'
        	str = %x[php --version]
        	
        	groups = str.scan(/PHP[ ]*([0-9]*.[0-9]*.[0-9]*)/i)
        	
        	result = groups[0][0]
        end
        
        return result
    end
end