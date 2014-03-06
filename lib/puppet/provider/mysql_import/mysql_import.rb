Puppet::Type.type(:mysql_import).provide(:ruby) do

  def files()
	  if (resource.refreshonly?)
	    return resource[:path]
	  end
	  
	  return nil
  end

  def files=(val)
  	val.each { |file|
		if resource[:cwd]
	      Dir.chdir resource[:cwd] do
	      	files = Dir.glob(file).sort
	      	
	      	run_files_command(files)
	      end
	    else
	      	files = Dir.glob(file).sort
	      	
	      	run_files_command(files)
	    end  	
  	}	    
  end

  def run_files_command(files)
  	files.each { |file| 
  		output, status = run_file_command(file)
		
		if status != 0
      		self.fail("Error executing SQL; mysql returned #{status}: '#{output}'")
      	else
      		if files.count > 1
      			self.notice("SQL File #{file} successfully executed")
      		end
   		end
  	}
  end
  
  def run_file_command(file)
    command = [resource[:mysql_bin]]
    command.push("--default-character-set=#{resource[:db_charset]}") if resource[:db_charset]
    command.push("--host=#{resource[:db_host]}") if resource[:db_host]
    command.push("--port=#{resource[:db_port]}") if resource[:db_port]
    command.push("--user=#{resource[:db_user]}") if resource[:db_user]
    command.push("--password=#{resource[:db_password]}") if resource[:db_password]
    command.push(resource[:db_name]) if resource[:db_name]

    if resource[:cwd]
      Dir.chdir resource[:cwd] do
        run_command(command, file, resource[:mysql_user], resource[:mysql_group])
      end
    else
      run_command(command, file, resource[:mysql_user], resource[:mysql_group])
    end
  end
  
  def run_command(command, stdinfile, user, group)
    if Puppet::PUPPETVERSION.to_f < 3.4
      Puppet::Util::SUIDManager.run_and_capture(command, user, group, {:stdinfile => stdinfile})
    else
      output = Puppet::Util::Execution.execute(command, {
      	:stdinfile => stdinfile,
      	:user => user,
      	:group => group,      
        :failonfail => false,
        :combine => true,
        :override_locale => true,
        :custom_environment => {}
      })
      [output, $CHILD_STATUS.dup]
    end
  end

end