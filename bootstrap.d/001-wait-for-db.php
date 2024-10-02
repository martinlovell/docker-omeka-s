<?php

require 'bootstrap.php';

$application = Omeka\Mvc\Application::init(require 'application/config/application.config.php');

$services = $application->getServiceManager();
$connection = $services->get('Omeka\Connection');
while (1) {
    try {
        $connection->query('select 1');
    } catch (\Exception $e) {
        echo "Waiting for database...\n";
        sleep(1);
        continue;
    }
    break;
}
