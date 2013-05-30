#!/usr/bin/php
<?php
define('OXID_CONFIG_KEY', 'fq45QS09_fqyx09239QQ');
define('OXID_SHOPID', 'oxbaseshop');

define('OXID_VARTYPE_BOOL', 'bool');
define('OXID_VARTYPE_STRING', 'str');
define('OXID_VARTYPE_ARR', 'aar');
define('OXID_VARTYPE_AARR', 'aarr');

function oxid_connect($url, $db, $user, $password) {
	$link = mysql_connect($url, $user, $password);
	if (!$link) {
		//exit('Connection failed.');
		exit(1);
	}
	
	$db_selected = mysql_select_db($db, $link);
	if (!$db_selected) {
		//exit('Select DB failed ' . mysql_error($link));
		exit(2);
	}
	
	return $link;
}

function oxid_close($link) {
	return mysql_close($link);
}

function oxid_db_error($link) {
	return mysql_error($link);
}

function oxid_serialize_value($varvalue, $vartype) {
	switch($vartype) {
		case OXID_VARTYPE_BOOL: return isset($varvalue) ? '1' : '0';
		case OXID_VARTYPE_ARR: return serialize($varvalue);
		case OXID_VARTYPE_AARR: return serialize($varvalue);
		default: return $varvalue;
	}
}

function oxid_deserialize_value($varvalue, $vartype) {
	switch($vartype) {
		case OXID_VARTYPE_ARR: return unserialize($varvalue);
		case OXID_VARTYPE_AARR: return unserialize($varvalue);
		default: return $varvalue;
	}
}

function oxid_set_varvalue($link, $varname, $varvalue, $vartype, $shopid = OXID_SHOPID, $config_key = OXID_CONFIG_KEY) {
	$aRet = oxid_fetch_varvalues($link, $varname, $shopid, $config_key);
	$storevalue = oxid_serialize_value($varvalue, $vartype);	
	
	if ($aRet) {		
		$query = sprintf("UPDATE oxconfig SET oxvarvalue = ENCODE('%s', '%s') where oxid = '%s'",
   				mysql_real_escape_string($storevalue),
    	 		mysql_real_escape_string($config_key),
				mysql_real_escape_string($aRet['oxid']));
	} else {		
		$query = sprintf("INSERT INTO oxconfig (oxid, oxshopid, oxvarname, oxvartype, oxvarvalue) VALUES(MD5('%s'),'%s', '%s', '%s', ENCODE('%s', '%s'))",
				mysql_real_escape_string(uniqid()),
				mysql_real_escape_string((string) $shopid),
				mysql_real_escape_string($varname),
				mysql_real_escape_string($vartype),
				mysql_real_escape_string($storevalue),
				mysql_real_escape_string($config_key));
	}
	
	return mysql_query($query, $link);
}

function oxid_fetch_varvalues($link, $varname, $shopid = OXID_SHOPID, $config_key = OXID_CONFIG_KEY) {
	$query = sprintf("SELECT oxid, oxvartype, DECODE(oxvarvalue, '%s') FROM oxconfig where oxvarname = '%s' and oxshopid = '%s'",
			mysql_real_escape_string($config_key),
			mysql_real_escape_string($varname),
			mysql_real_escape_string($shopid));
	
	$result = mysql_query($query, $link);
	
	if (!$result) {
		return false;
	}

	$row = mysql_fetch_row($result);

	if (!$row) {
		return false;
	}

	return array('oxid' => $row[0], 'oxvartype' => $row[1], 'oxrawvalue' => $row[2], 'oxvarvalue' => oxid_deserialize_value($row[2], $row[1]));
}

function oxid_get_bool($link, $varname, $shopid = OXID_SHOPID, $config_key = OXID_CONFIG_KEY) {
	$ret = oxid_fetch_varvalues($link, $varname, $shopid, $config_key);
	
	if($ret) {
		return $ret['oxvarvalue'];
	}
	
	return false;
}

function oxid_get_str($link, $varname, $shopid = OXID_SHOPID, $config_key = OXID_CONFIG_KEY) {
	$ret = oxid_fetch_varvalues($link, $varname, $shopid, $config_key);

	if($ret) {
		return $ret['oxvarvalue'];
	}

	return false;
}

function oxid_get_arr($link, $varname, $shopid = OXID_SHOPID, $config_key = OXID_CONFIG_KEY) {
	$ret = oxid_fetch_varvalues($link, $varname, $shopid, $config_key);

	if($ret) {
		return $ret['oxvarvalue'];
	}

	return false;
}

function oxid_get_aarr($link, $varname, $shopid = OXID_SHOPID, $config_key = OXID_CONFIG_KEY) {
	$ret = oxid_fetch_varvalues($link, $varname, $shopid, $config_key);

	if($ret) {
		return $ret['oxvarvalue'];
	}

	return false;
}

function oxid_set_bool($link, $varname, $blValue, $shopid = OXID_SHOPID, $config_key = OXID_CONFIG_KEY) {
	return oxid_set_varvalue($link, $varname, $str, OXID_VARTYPE_BOOL, $shopid, $config_key);
}

function oxid_set_string($link, $varname, $sValue, $shopid = OXID_SHOPID, $config_key = OXID_CONFIG_KEY) {
	return oxid_set_varvalue($link, $varname, $sValue, OXID_VARTYPE_STRING, $shopid, $config_key);
}

function oxid_set_arr($link, $varname, $sValue, $shopid = OXID_SHOPID, $config_key = OXID_CONFIG_KEY) {
	return oxid_set_varvalue($link, $varname, $sValue, OXID_VARTYPE_ARR, $shopid, $config_key);
}

function oxid_set_aarr($link, $varname, $sValue, $shopid = OXID_SHOPID, $config_key = OXID_CONFIG_KEY) {
	return oxid_set_varvalue($link, $varname, $sValue, OXID_VARTYPE_AARR, $shopid, $config_key);
}

function oxid_remove_var($link, $varname, $shopid = OXID_SHOPID) {
	$query = sprintf("DELETE FROM oxconfig where oxvarname = '%s' and oxshopid = '%s'",
   				mysql_real_escape_string($varname),
    	 		mysql_real_escape_string($shopid)); 
	
	return mysql_query($query, $link);
}