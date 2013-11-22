<?php

define('OX_IS_ADMIN', 1);

if (!defined('OX_BASE_PATH')) {
    define('OX_BASE_PATH', dirname(__FILE__) . DIRECTORY_SEPARATOR );
}

if ( !function_exists( 'getShopBasePath' )) {
	function getShopBasePath() { 
		return OX_BASE_PATH; 
	} 
}

if (file_exists(getShopBasePath().'bootstrap.php')) {
	require_once getShopBasePath() . "bootstrap.php";
	
	$oMetaData = oxNew('oxDbMetaDataHandler');
	
	exit($oMetaData->updateViews() ? 0 : "Update Views(5) failed.");
} else {
	if ( !function_exists( 'isAdmin' )) {
		function isAdmin() { 
			return true; 
		} 
	}	
	
	require_once getShopBasePath()."core/oxfunctions.php";
	require_once getShopBasePath()."core/oxsupercfg.php"; 
	require_once getShopBasePath()."core/oxdb.php";
	
	exit(oxDb::getInstance()->updateViews() ? 0 : "Update Views(448) failed.");
}