#!/usr/bin/php
<?php 

$paharfile = $argv[1];
$target = $argv[2];

$iter = new RecursiveIteratorIterator(new RecursiveDirectoryIterator('phar://'.$paharfile), RecursiveIteratorIterator::CHILD_FIRST);
if (!function_exists('mkdirs')) {
	function mkdirs($arg) {
		if (strlen($arg) <= 2) return;
		if(!is_dir($arg)) {
			mkdirs(dirname($arg)); mkdir($arg);
		}
	}
}

foreach ($iter as $file) {
	$relPath = substr($file->getPathName(),	strlen('phar://'.$paharfile));
	$fullPath = $target.$relPath;
	if ($iter->isDir()) {
		mkdirs($fullPath);
	} else {
		mkdirs(dirname($fullPath)); $contents =
		file_get_contents($file->getPathName()); file_put_contents($fullPath, $contents);
	}
}
