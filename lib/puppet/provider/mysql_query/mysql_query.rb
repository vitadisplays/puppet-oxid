Puppet::Type.type(:mysql_query).provide(:mysql_query) do
    desc "MySQL exec"

	defaultfor :kernel => 'Linux'
	
	commands :mysql => "mysql"
	
	def defaults_file
	    if File.file?("#{Facter.value(:root_home)}/.my.cnf")
	      "--defaults-extra-file=#{Facter.value(:root_home)}/.my.cnf"
	    else
	      nil
	    end
    end

	def defaults_database
	    if @resource[:database] != nil
	      database_option = "--database=#{@resource[:database]}"
	      
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
    
    def query=(query_input)
		debug "running query"		
	  	mysql([defaults_file, "--default-character-set=#{@resource[:charset]}", "--host=#{@resource[:host]}", "--port=#{@resource[:port]}", defaults_user, defaults_password, defaults_database, "-e", query_input].compact)
		
		exit_code = $?
		if exit_code != 0
  			raise "Error on executing query '#{query_input}'"
  		else
  			info "File '#{query_input}' successfully executed."
  		end
  		
		return true
	end
	
	def query
		query_input = @resource[:query]
		debug "running query"		
	  	mysql([defaults_file, "--default-character-set=#{@resource[:charset]}", "--host=#{@resource[:host]}", "--port=#{@resource[:port]}", defaults_user, defaults_password, defaults_database, "-e", query_input].compact)

		exit_code = $?
		if exit_code != 0
  			raise "Error on executing query '#{query_input}'"
  		else
  			info "File '#{query_input}' successfully executed."
  		end
  		
		return true
	end
	
	def file=(file_source)
	  	mysql([defaults_file, "--default-character-set=#{@resource[:charset]}", "--host=#{@resource[:host]}", "--port=#{@resource[:port]}", defaults_user, defaults_password, defaults_database, "<", file_source].compact)
	
		exit_code = $?
		if exit_code != 0
  			raise "Error on executing file '#{file}'"
  		else
  			info "File '#{file}' successfully executed."
  		end
  			
		return true
	end
	
	def file
		file_source = @resource[:file]
	  	mysql([defaults_file, "--default-character-set=#{@resource[:charset]}", "--host=#{@resource[:host]}", "--port=#{@resource[:port]}", defaults_user, defaults_password, defaults_database, "<", file_source].compact)
	
		exit_code = $?
		if exit_code != 0
  			raise "Error on executing file '#{file}'"
  		else
  			info "File '#{file}' successfully executed."
  		end
  			
		return true
	end
	
	def directory=(directory_source)
	  	Dir.glob(File.join(directory_source, "*.sql")).each do|f|
			file(f)
 		end
	end
	
	def directory
		directory_source = @resource[:directory]
	  	Dir.glob(File.join(directory_source, "*.sql")).each do|f|
			file(f)
 		end
	end	
end
