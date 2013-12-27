Puppet::Type.newtype(:replaceinfiles) do
    @doc = "Replace text tokens in text files"

    ensurable

    newparam(:name) do
        desc "The full path to the file."

        isnamevar
	end	   
	        
    newparam(:tokens) do
        desc "text/regex token to replace."                      
    end
end