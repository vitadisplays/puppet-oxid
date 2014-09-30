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
  		if val == 'optimize'
  			entries = get_entries_by_query("SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA = '#{resource[:db_name]}' AND Data_free > 0 AND ENGINE IN ('MyISAM','InnoDB','ARCHIVE');")
  		else
  			entries = get_entries_by_query("SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA = '#{resource[:db_name]}';")
  		end
  	end	
  	
  	views = get_entries_by_query("SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_TYPE = 'VIEW' AND TABLE_SCHEMA = '#{resource[:db_name]}';")
  	
  	if val == 'optimize'
  		optimize = []
  		entries.each { |e|
  			stmt = "OPTIMIZE TABLE #{e};"
  			if views.include? e
  				self.notice("View '{e}' optimizing skipped.")
  			else
  				output, status = run_sql_command(stmt)
  			
			    if status != 0
			      self.fail("Error executing '#{stmt}'; mysql returned #{status}: '#{output}'")
			     else
			      optimize.push(e)
			    end
  			end  			
  		}
  		
  		if optimize.count > 0
  			self.notice("Table '#{optimize.join(', ')}' optimized.")
  		end   	
	elsif val == 'delete'		
		deleted = []
  		entries.each { |e|
  			stmt = "DELETE * FROM #{e} WHERE 1=1;"
  			if views.include? e
  				self.notice("View '{e}' deleting skipped.")
  			else
  				output, status = run_sql_command(stmt)
  			
			    if status != 0
			      self.fail("Error executing '#{stmt}'; mysql returned #{status}: '#{output}'")
			     else
			      deleted.push(e)
			    end
  			end  			
  		}
  		
  		if deleted.count > 0
  			self.notice("Rows of Table '#{deleted.join(', ')}' deleted.")
  		end  	
  	else
  		dropped = []
  		
  		entries.each { |e|
  			stmt = "DROP TABLE IF EXISTS #{e};"
  			if views.include? e
  				stmt = "DROP VIEW IF EXISTS #{e};"
  			end
  			
  			output, status = run_sql_command(stmt)
  			
		    if status != 0
		      self.fail("Error executing '#{stmt}'; mysql returned #{status}: '#{output}'")
		     else
		      dropped.push(e)
		    end  			
  		}
  		
  		if dropped.count > 0
  			self.notice("Table '#{dropped.join(', ')}' dropped.")
  		end
  	end
  end

  def get_entries_by_query(query)
  	output, status = run_sql_command(query)
  	
  	if status != 0
      self.fail("Error executing SQL; mysql returned #{status}: '#{output}'")
    end
    
    entries = []
	output.each_line do |line|
  		entries << line.chop
	end
	
	return entries
  end
   
  def run_sql_command(sql)
    command = [resource[:mysql_bin]]
    command.push("--host=#{resource[:db_host]}") if resource[:db_host]
    command.push("--port=#{resource[:db_port]}") if resource[:db_port]
    command.push("--user=#{resource[:db_user]}") if resource[:db_user]
    command.push("--password=#{resource[:db_password]}") if resource[:db_password]
    command.push("--database=#{resource[:db_name]}")  
    
    command.push("-BNe", sql)

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