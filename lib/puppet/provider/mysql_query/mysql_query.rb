Puppet::Type.type(:mysql_query).provide(:ruby) do
  desc "Executes a mysql query"
  
  def command()
	  if (resource.refreshonly?)
	    return resource[:command]
	  end
	  
	  return nil
  end

  def command=(val)
    output, status = run_sql_command(val)

    if status != 0
      self.fail("Error executing SQL; mysql returned #{status}: '#{output}'")
    end
  end

  def run_sql_command(sql)
    command = [resource[:mysql_bin]]
    command.push("--default-character-set=#{resource[:db_charset]}") if resource[:db_charset]
    command.push("--host=#{resource[:db_host]}") if resource[:db_host]
    command.push("--port=#{resource[:db_cport]}") if resource[:db_port]
    command.push("--user=#{resource[:db_user]}") if resource[:db_user]
    command.push("--password=#{resource[:db_password]}") if resource[:db_password]
    command.push("--database=#{resource[:db_name]}") if resource[:db_name]
    
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