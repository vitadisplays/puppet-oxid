Puppet::Type.type(:mysql_tables).provide(:ruby) do
  desc "Drop or delete tables/views"
  
  def command()
	  if (resource.refreshonly?)
	    return resource[:command]
	  end
	  
	  return nil
  end

  def command=(val)
  
  	entries = []
  	
  	if resource[:tables]
  		entries = resource[:tables]
  	elsif resource[:query]
  		entries = get_entries_by_query(resource[:query])
  	else
  		entries = get_entries_by_query("SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA = '#{resource[:db_name]}';")
  	end
  	
  	views = get_entries_by_query("SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_TYPE = 'VIEW' AND TABLE_SCHEMA = '#{resource[:db_name]}';")
  	
	if val == 'delete'
  		entries.each { |e|
  			stmt = "DELETE * FROM #{e} WHERE 1=1;"
  			if views.include? e
  				self.notice("View '{e}' deleting skipped.")
  			else
  				output, status = run_sql_command(stmt)
  			
			    if status != 0
			      self.fail("Error executing '#{stmt}'; mysql returned #{status}: '#{output}'")
			     else
			      self.notice("Table '{e}' entries purged.")
			    end
  			end  			
  		}  	
  	else
  		entries.each { |e|
  			stmt = "DROP TABLE IF EXISTS #{e};"
  			if views.include? e
  				stmt = "DROP VIEW IF EXISTS #{e};"
  			end
  			
  			output, status = run_sql_command(stmt)
  			
		    if status != 0
		      self.fail("Error executing '#{stmt}'; mysql returned #{status}: '#{output}'")
		     else
		      self.notice("Table/View '{e}' dropped.")
		    end  			
  		}
  	end
  end

  def get_entries
  	if resource[:tables]
  		return resource[:tables]
  	elsif resource[:query]
  		return get_entries_by_query(resource[:query])
  	else
  		return get_entries_by_query("show tables")
  	end
  end
 
  def get_entries_by_query(query)
  	output, status = run_sql_command(query, '-B -N')
  	
  	if status != 0
      self.fail("Error executing SQL; mysql returned #{status}: '#{output}'")
    end
    
    entries = []
	output.each_line do |line|
  		entries << line.chop
	end
	
	return entries
  end
   
  def run_sql_command(sql, options = nil)
    command = [resource[:mysql_bin]]
    command.push("--default-character-set=#{resource[:db_charset]}") if resource[:db_charset]
    command.push("--host=#{resource[:db_host]}") if resource[:db_host]
    command.push("--port=#{resource[:db_port]}") if resource[:db_port]
    command.push("--user=#{resource[:db_user]}") if resource[:db_user]
    command.push("--password=#{resource[:db_password]}") if resource[:db_password]
    command.push("--database=#{resource[:db_name]}") if resource[:db_name]
    
    command.push(options) if options
    
    command.push("-e", sql)

    if resource[:cwd]
      Dir.chdir resource[:cwd] do
        run_command(command, resource[:mysql_user], resource[:mysql_group])
      end
    else
      run_command(command, resource[:mysql_user], resource[:mysql_group])
    end
  end
  
  def run_command(command, user, group)
    if Puppet::PUPPETVERSION.to_f < 3.4
      Puppet::Util::SUIDManager.run_and_capture(command, user, group)
    else
      output = Puppet::Util::Execution.execute(command, {
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