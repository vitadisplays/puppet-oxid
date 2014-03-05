Puppet::Type.type(:mysql_query_old).provide(:mysql_query_old) do
    desc "MySQL exec"
	
	commands :mysql => "mysql"

	def defaults_database
	    if @resource[:database] != nil
	      database_option = "--database=#{@resource[:database]}"
	      
	      return database_option
	    else
	      nil
	    end
    end
    
    def defaults_database_single
	    if @resource[:database] != nil
	      database_option = "#{@resource[:database]}"
	      
	      return database_option
	    else
	      nil
	    end
    end
    
   	def defaults_user
	    if @resource[:user] != nil
	      user_option = "--user=#{@resource[:user]}"
	      
	      return user_option
	    else
	      nil
	    end
    end
    
   	def defaults_password
	    if @resource[:password] != nil
	      password_option = "--password=#{@resource[:password]}"
	      
	      return password_option
	    else
	      nil
	    end
    end    
    
    def query=(query)
    	query_input = "\"#{query}\""
    	
	  	if execute_mysql(["--default-character-set=#{@resource[:charset]}", "--host=#{@resource[:host]}", "--port=#{@resource[:port]}", defaults_user, defaults_password, defaults_database_single, "-e", query_input].compact) != true
	  		raise "Error on executing query '#{query}'"
		end
	  		
	  	info "Query '#{query}' successfully executed."
	  	
		return true
	end
	
	def query
		return "not executed"
	end
	
	def file=(file_source)
		if execute_mysql_file(["--default-character-set=#{@resource[:charset]}", "--host=#{@resource[:host]}", "--port=#{@resource[:port]}", defaults_user, defaults_password, defaults_database_single].compact, file_source) != true
			raise "Error on executing file '#{file}'"
		end		
		
		info "File '#{file}' successfully executed."
		
		return true
	end
	
	def file
		return "not executed"
	end
	
	def directory=(directory_source)
	  	Dir.glob(File.join(directory_source, "*.sql")).each do|f|
			file(f)
 		end
	end
	
	def directory
		return "not executed"
	end
	
	def execute_mysql(args)
		if args.is_a?(Array)
      		args = args.flatten.map(&:to_s)
      		str = args.join(" ")
   		 elsif args.is_a?(String)
      		str = args
    	end
    	
		command = "mysql #{str}"
		
		`#{command}`
		
		exit_code = $?
		if exit_code != 0
			fail "command: '#{command}'"
  			return false
		end
		  			
		return true
	end
	
	def execute_mysql_file(args, file)
		if args.is_a?(Array)
      		args = args.flatten.map(&:to_s)
      		str = args.join(" ")
   		 elsif args.is_a?(String)
      		str = args
    	end
    	
		command = "mysql #{str}"
		
		`#{command} < #{file}`
		
		#pid = spawn(command, :in=>[file])
		
		#Process.wait pid
		  			
		exit_code = $?
		if exit_code != 0
			fail "command: '#{command}'"
  			return false
		end
		  			
		return true
	end
end
