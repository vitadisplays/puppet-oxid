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

$link = oxid_connect($url, $db, $user, $password);

$result = 1;

switch($command) {
	case 'set':
		$config_key = $json->{'configkey'};
		$vartype = $json->{'vartype'};
		$varname = $json->{'varname'};
		$varvalue = $json->{'varvalue'};
		
		$rawvalue = oxid_config_unserialize($vartype, $varvalue);
		
		$result = oxid_set_varvalue($link, $varname, $rawvalue, $vartype, $shopid, $config_key);
		
		break;
	case 'remove':
		$varname = $json->{'varname'};
		
		if (is_array($varname)) {
			$result = 0;
			foreach($varname as $v) {
				 if(!oxid_remove_var($link, $v, $shopid)) {
				 	$result = 1;
				 	break;
				 }
			}
		} else {
			$result = oxid_remove_var($link, $varname, $shopid);
		}
		break;
}

oxid_close($link);

exit($result);

function oxid_config_unserialize($vartype, $varvalue) {
	switch($vartype) {
		case OXID_VARTYPE_BOOL: 
			return isset($varvalue) && $varvalue == 1 ? '1' : '0';
		default: return $varvalue;
	}
}