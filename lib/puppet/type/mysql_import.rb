Puppet::Type.newtype(:mysql_import) do

  newparam(:name) do
    desc "An arbitrary tag for your own reference; the name of the message."
    isnamevar
  end

  newproperty(:files, :array_matching => :all) do
    desc 'The SQL command to execute via mysql.'

    defaultto { @resource[:name] }

    def change_to_s(currentvalue, newvalue)
      "executed successfully"
    end
    
    def sync(refreshing = false)
      if (!@resource.refreshonly? || refreshing)
        super()
      else
        nil
      end
    end
  end

  newparam(:pattern) do
    desc "The pattern for directory mode"
    defaultto("*.sql")
  end
  
  newparam(:db_host) do
    desc "The mysql host"
    defaultto("localhost")
  end
  
  newparam(:db_port) do
    desc "The mysql port"
    defaultto(3306)
  end
  
  newparam(:db_name) do
    desc "The name of the database to execute the SQL command against."
  end

  newparam(:db_user) do
    desc "The mysql user account under which the sql command should be executed."
    defaultto("root")
  end

  newparam(:db_password) do
    desc "The mysql password under which the sql command should be executed."
  end
  
  newparam(:db_charset) do
    desc "The mysql charset under which the sql command should be executed."
  end
  
  newparam(:mysql_bin) do
    desc "The mysql binary."
    defaultto("mysql")
  end
  
  newparam(:mysql_user) do
    desc "The mysql user account under which the mysql binary should be executed."
    defaultto("mysql")
  end
    
  newparam(:mysql_group) do
    desc "The mysql group account under which the mysql binaryd should be executed."
    defaultto("mysql")
  end
      
  newparam(:cwd, :parent => Puppet::Parameter::Path) do
    desc "The working directory under which the mysql command should be executed."
    defaultto("/tmp")
  end

  newparam(:refreshonly, :boolean => true) do
    desc "If 'true', then the SQL will only be executed via a notify/subscribe event."

    defaultto(:false)
    newvalues(:true, :false)
  end

  def refresh()
    self.property(:path).sync(path)
  end

end