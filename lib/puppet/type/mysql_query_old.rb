Puppet::Type.newtype(:mysql_query_old) do
    @doc = "Run MySQL Statements"

  	newparam(:name) do
      desc "The name of the resource"
    end
  	
  	newparam(:host) do
        desc "The mysql host"
        
        defaultto 'localhost'
    end
    
    newparam(:port) do
        desc "The mysql port"
        
         defaultto 3306
    end
    
    newparam(:user) do
        desc "The mysql user"
    end
        
    newparam(:password) do
        desc "The mysql password"
    end
     
    newparam(:database) do
        desc "The mysql database"
    end
    
    newparam(:charset) do
        desc "The charset to use"
        
        defaultto "latin1"
    end 
    
	newproperty(:query) do
        desc "The query"
    end
    
    newproperty(:file) do
        desc "The file including statements"
    end
    
    newproperty(:directory) do
        desc "The directory including sql files"
    end  
end