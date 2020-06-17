<?php
	# ------------------------------------------------------------------------
	#  Set environment variables
	# ------------------------------------------------------------------------
	$cfgfilename = "config.json";
    $logfilename = "log.json";

	$platformBase   = $_SERVER['DOCUMENT_ROOT'];
	$moduleBase     = $platformBase . dirname($_SERVER['PHP_SELF']) ;
	$scriptsBase    = $moduleBase . '/scripts' ;
	// $rootBase	= "/root/.local/share/storj/identity" ;


	$file        = $moduleBase  . DIRECTORY_SEPARATOR . $cfgfilename  ;
    $logfile        = $moduleBase  . DIRECTORY_SEPARATOR . $logfilename  ;
	$startScript    = $scriptsBase . DIRECTORY_SEPARATOR . 'storagenodestart.sh' ;
	$stopScript     = $scriptsBase . DIRECTORY_SEPARATOR . 'storagenodestop.sh' ;
	$updateScript	= $scriptsBase . DIRECTORY_SEPARATOR . 'storagenodeupdate.sh' ;
	$checkScript    = $scriptsBase . DIRECTORY_SEPARATOR . 'checkStorj.sh' ;
	$isRunning      = $scriptsBase . DIRECTORY_SEPARATOR . 'isRunning.sh' ;
	$storageBinary  = $scriptsBase . DIRECTORY_SEPARATOR . 'storagenode' ;
	$yamlPath	    = $scriptsBase . DIRECTORY_SEPARATOR . 'docker-compose_base.yml' ;
	$identityFile   = $moduleBase  . DIRECTORY_SEPARATOR . 'identity.pid' ;

?>