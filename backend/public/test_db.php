<?php
declare(strict_types=1);

header('Content-Type: text/plain; charset=utf-8');

$envFile = __DIR__ . '/../.env';
echo "ENV exists: " . (file_exists($envFile) ? "YES" : "NO") . "\n";

$config = require __DIR__ . '/../config.php';
echo "DSN: " . $config['dsn'] . "\n";
echo "User: " . $config['user'] . "\n";
echo "Password length: " . strlen($config['password']) . "\n";

try {
    $pdo = new PDO($config['dsn'], $config['user'], $config['password'], [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    ]);
    echo "SUCCESS: Connected to Database!\n";
    $stmt = $pdo->query("SELECT id, name FROM stores LIMIT 1");
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo "Stores query OK: " . json_encode($rows) . "\n";
} catch (Throwable $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
