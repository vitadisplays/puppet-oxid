module Puppet::Parser::Functions
    newfunction(:generate_password, :type => :rvalue) do |*arguments|
	    arguments = arguments.shift if arguments.first.is_a?(Array)
	
	    raise Puppet::ParseError, "generate_password(): Wrong number of arguments " +
	      "given (#{arguments.size} for 1)" if arguments.size < 1
	
	    size = arguments.shift
	
	    unless size.class.ancestors.include?(Numeric) or size.is_a?(String)
	      raise Puppet::ParseError, 'generate_password(): Requires a numeric ' +
	        'type to work with'
	    end
	
	    # Numbers in Puppet are often string-encoded which is troublesome ...
	    if size.is_a?(String) and size.match(/^\d+$/)
	      size = size.to_i
	    else
	      raise Puppet::ParseError, 'generate_password(): Requires a non-negative ' +
	        'integer value to work with'
	    end       
    
    	chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
		newpass = ""
		1.upto(size) { |i| newpass << chars[rand(chars.size-1)] }
		
    	return newpass
    end
end