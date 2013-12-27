# escape slashes in a String
module Puppet::Parser::Functions
    newfunction(:slash_escape_hash, :type => :rvalue) do |args|
    	result = {}
    	
    	args[0].each do |key, value|
    		result[key.gsub(/\//, '\\/')] = value.gsub(/\//, '\\/')
        end
        
        return result
    end
end