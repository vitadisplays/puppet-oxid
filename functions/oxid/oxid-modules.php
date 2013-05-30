#!/usr/bin/php
<?php 
include_once 'oxid-config-inc.php';

$json = json_decode($argv[1]);


$command = $json->{'command'};
$url = $json->{'host'};
$db = $json->{'db'};
$user = $json->{'user'};
$password = $json->{'password'};
$shopid = $json->{'shopid'};

/*$command = $argv[1];
 $url = $argv[2];
$db = $argv[3];
$user = $argv[4];
$password = $argv[5];
$shopid = $argv[6];
$config_key = $argv[7];
$module = $argv[8];
$class = $argv[9];*/

$link = oxid_connect($url, $db, $user, $password);

switch($command) {
	case 'clear' :	
		if (!oxid_remove_var($link, 'aModules', $shopid)) {
			//exit('aModules clear failed ' . mysql_error($link));
			exit(0);
		}

		break;

	case 'add' :
		$module = $json->{'module'};
		$config_key = $json->{'configkey'};
		
		$aarr = oxid_get_aarr($link, 'aModules', $shopid, $config_key);

		if (!$aarr) {
			$aarr = array();
		}

		

		foreach ($module as $key => $value) {
			$moduleClasses = is_array($value) ? $value : array($value);

			if (array_key_exists($key, $aarr)) {
				$classes = array_map('trim',explode("&", $aarr[$key]));

				foreach ($moduleClasses as $class) {
					if (!in_array($class, $classes)) {
						$classes[] = $class;
					}
				}
					
				$aarr[$key] = implode(' & ', $classes);
			} else {
				$aarr[$key] = implode(' & ', $moduleClasses);;
			}
		}
			
		if(!oxid_set_aarr($link, 'aModules', $aarr, $shopid, $config_key)) {
			//exit('aModules add failed ' . oxid_db_error($link));
			exit(20);
		}


		break;

	case 'set' :
		$module = $json->{'module'};
		$config_key = $json->{'configkey'};
		
		$aarr = oxid_get_aarr($link, 'aModules', $shopid, $config_key);

		if (!$aarr) {
			$aarr = array();
		}
		
		foreach ($module as $key => $value) {
			$moduleClasses = is_array($value) ? $value : array($value);

			$aarr[$key] = implode(' & ', $moduleClasses);
		}

		if(!oxid_set_aarr($link, 'aModules', $aarr, $shopid, $config_key)) {
			//exit('aModules set failed: ' . oxid_db_error($link));
			exit(30);
		}

		break;
			
	case 'remove' :
		$module = $json->{'module'};
		$config_key = $json->{'configkey'};
		
		$aarr = oxid_get_aarr($link, 'aModules', $shopid, $config_key);

		$modules = is_array($module) ? $module : array($module);
		$change = false;

		if ($aarr) {
			foreach ($modules as $key => $value) {
				if (array_key_exists($key, $aarr)) {

					$classes = array_map('trim',explode("&", $aarr[$key]));
					$moduleClasses = is_array($value) ? $value : array($value);

					foreach($moduleClasses as $class) {
						if (in_array($class, $classes)) {
							$classes = array_diff($classes, array($class));

							if (count($classes)) {
								$aarr[$module] = implode(' & ', $classes);

								$change = true;
							} else {
								unset($aarr[$module]);

								$change = true;
							}
						}
					}
				}
			}

			if ($change) {
				if(!oxid_set_aarr($link, 'aModules', $aarr, $shopid, $config_key)) {
					//exit('aModules remove failed: ' . oxid_db_error($link));
					exit(40);
				}
			}
		}

		break;

	case 'delete' :
		$module = $json->{'module'};
		$config_key = $json->{'configkey'};
		
		$aarr = oxid_get_aarr($link, 'aModules', $shopid, $config_key);	
		
		if ($aarr) {
			$modules = array();
			if(is_array($module)) {
				$modules = $module;
			} else {
				$modules = array($module);
			}

			$change = false;
				
			foreach($modules as $m) {
				if (array_key_exists($m, $aarr)) {
					unset($aarr[$m]);
						
					$change = true;
				}
			}

			if($change) {
				if(!oxid_set_aarr($link, 'aModules', $aarr, $shopid, $config_key)) {
					//exit('aModules delete failed: ' . oxid_db_error($link));
					exit(51);
				}
			}
		}

		break;
}

oxid_close($link);

exit(0);