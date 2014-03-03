Puppet::Type.type(:mysql_exec).provide(:mysql_exec) do
    desc "MySQL exec"

	commands :mysql => "mysql"
	
	def defaults_file
	    if File.file?("#{Facter.value(:root_home)}/.my.cnf")
	      "--defaults-extra-file=#{Facter.value(:root_home)}/.my.cnf"
	    else
	      nil
	    end
    end

	def defaults_database
	    if #{@resource[:database]}
	      "--database='#{@resource[:database]}'"
	    else
	      nil
	    end
    end
    
   	def defaults_user
	    if #{@resource[:user]}
	      "--user='#{@resource[:user]}'"
	    else
	      nil
	    end
    end
    
   	def defaults_password
	    if #{@resource[:password]}
	      "--password='#{@resource[:password]}'"
	    else
	      nil
	    end
    end    
    
	def statement=(statement)
		info "executing statement #{statement}"
	  	mysql([defaults_file, '--default-character-set='#{@resource[:charset]}'", '--host='#{@resource[:host]}'", '--port='#{@resource[:port]}'", defaults_user, defaults_password, defaults_database, '-e', statement].compact)
	end
	
	def file=(file)
	  	info "executing file #{file}"
	  	mysql([defaults_file, '--default-character-set='#{@resource[:charset]}'", '--host='#{@resource[:host]}'", '--port='#{@resource[:port]}'", defaults_user, defaults_password, defaults_database, "< #{@resource[:file]}"].compact)
	end
	
	def directory=(directory)
	  	info "executing files from #{directory}"
	  	Dir.glob(directory, "#{@resource[:pattern]}")).each do|f|
			file(f)
 		end
	end	
end