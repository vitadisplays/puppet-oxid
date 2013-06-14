#!/usr/bin/php
<?php 

$file = $argv[1];
$pattern = $argv[2];
$replacement = $argv[3];

if($contents = file_get_contents($file)) {
	if ($contents = preg_replace($pattern, $replacement, $contents)) {
		if(file_put_contents($file, $contents)) {
			exit(0);
		}
	}
}

exit(1);