Puppet::Type.type(:mysql_exec).provide(:mysql) do
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
    
	def create
	  if @resource[:statement]
	  	info "executing statement @resource[:statement]"
	  	mysql([defaults_file, '--default-character-set='#{@resource[:charset]}'", '--host='#{@resource[:host]}'", '--port='#{@resource[:port]}'", defaults_user, defaults_password, defaults_database, '-e', "#{@resource[:statement]}"].compact)
	  else if @resource[:file]
	  	info "executing file @resource[:file]"
	  	mysql([defaults_file, '--default-character-set='#{@resource[:charset]}'", '--host='#{@resource[:host]}'", '--port='#{@resource[:port]}'", defaults_user, defaults_password, defaults_database, "< #{@resource[:file]}"].compact)
	  else if @resource[:directory]
	  	info "executing files from @resource[:directory]"
	  	Dir.glob(File.join("#{@resource[:directory]}", "#{@resource[:pattern]}")).each do|f|
	  		info "executing file " + f
			mysql([defaults_file, '--default-character-set='#{@resource[:charset]}'", '--host='#{@resource[:host]}'", '--port='#{@resource[:port]}'", defaults_user, defaults_password, defaults_database, "< " + f].compact)
 		end	  	
	  end
	end
	
    def destroy

    end

    def exists?
        false
    end
end