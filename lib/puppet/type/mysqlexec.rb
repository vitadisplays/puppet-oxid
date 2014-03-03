Puppet::Type.newtype(:mysql_exec) do
    @doc = "Run MySQL Statements"

  	newparam(:name, :namevar => true) do
    	desc 'Name to describe the exec.'

   	 munge do |value|
     	 value.delete("'")
    	end
 	end
  	
  	newproperty(:host) do
        desc "The mysql host"
        
        defaultto 'localhost'
    end
    
    newproperty(:port) do
        desc "The mysql port"
        
         defaultto 3306
    end
    
    newproperty(:user) do
        desc "The mysql user"
        
        defaultto nil
    end
        
    newproperty(:password) do
        desc "The mysql password"
        
        defaultto nil
    end
     
    newproperty(:database) do
        desc "The mysql database"
        
        defaultto nil
    end
                
    newproperty(:statement) do
        desc "The statement"
        
        defaultto nil
    end

    newproperty(:file) do
        desc "The file including statement"
        
        defaultto nil
    end
    
    newproperty(:directory) do
        desc "The directory path including statements files"
        
        defaultto nil
    end
    
    newproperty(:pattern) do
        desc "The directory pattern to search for"
        
        defaultto "*.sql"
    end
    
    newproperty(:charset) do
        desc "The charset to use"
        
        defaultto "latin1"
    end    
end