class sshutils {
	define tunnel (
	        $ensure = "present",
	        $ssh_host = "",
	        $ssh_port = 22,
	        $ssh_user = "",
	        $ssh_key  = "",
	        $target_host = "",
	        $target_port = "",
	        $local_port = "",
	        $command = ""
	    ){
	        if ($ssh_host and $ssh_port and $ssh_user and $ssh_key and $target_host and $target_port and $local_port ) {
	            if $command == "" {
	             $tunnel_command = "ssh -oStrictHostKeyChecking=no -L ${local_port}:${target_host}:${target_port} -i ${ssh_key} ${ssh_user}@${ssh_host} /usr/local/bin/waitforever.sh"
	            } else {
	              $tunnel_command = "ssh -oStrictHostKeyChecking=no -L ${local_port}:${target_host}:${target_port} -i ${ssh_key} ${ssh_user}@${ssh_host} ${command}"
	            }
	            
	            case $ensure {
	                present: {
	                    exec { "setup_ssh_tunnel_$name":
	                        command     => "${tunnel_command} &",
	                        path    => "/usr/bin:/usr/sbin:/bin",
	                        unless      => "/bin/ps -C ssh -F | /bin/grep '${tunnel_command}'",
	                    }
	                }
	                absent: {
	                    exec { "kill_ssh_tunnel_$name":
	                        command => "kill `ps -C ssh -F | grep '${tunnel_command}' | awk '{print \$2}'`",
	                        path    => "/usr/bin:/usr/sbin:/bin",
	                        onlyif => "ps -C ssh -F | grep '${tunnel_command}'"
	                    }
	                }
	            }
	        }
	        else {
	            warning("ssh::tunnel: you didnt supply enough parameters")
	        }
	    }	
}