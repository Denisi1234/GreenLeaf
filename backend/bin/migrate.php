<?php
declare(strict_types=1);

require __DIR__ . '/../src/Database.php';
$config = require __DIR__ . '/../config.php';
if (!is_dir(__DIR__ . '/../storage')) {
    mkdir(__DIR__ . '/../storage', 0700, true);
}
$db = new Database($config);
$db->migrate();
echo "TrackMauzo database is ready.\n";
