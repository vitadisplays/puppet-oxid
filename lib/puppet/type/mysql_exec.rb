Puppet::Type.newtype(:mysql_exec) do
    @doc = "Run MySQL Statements"

  	newparam(:name, :namevar => true) do
    	desc 'Name to describe the exec.'

   	 munge do |value|
     	 value.delete("'")
    	end
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
        
        defaultto nil
    end
        
    newparam(:password) do
        desc "The mysql password"
        
        defaultto nil
    end
     
    newparam(:database) do
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
    
    newparam(:pattern) do
        desc "The directory pattern to search for"
        
        defaultto "*.sql"
    end
    
    newparam(:charset) do
        desc "The charset to use"
        
        defaultto "latin1"
    end
    
    validate do
        unless self[:statement] or self[:file] or self[:directory]
            fail "Exactly one of statement, file or directory is required."
        end
        if self[:statement] and self[:file]
            fail "Use either statement or file, not both."
        end
        
        if self[:directory] and self[:file]
            fail "Use either directory or file, not both."
        end
        
        if self[:directory] and self[:statement]
            fail "Use either directory or statement, not both."
        end
    end   
end