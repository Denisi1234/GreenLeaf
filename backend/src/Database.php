<?php
declare(strict_types=1);

final class Database
{
    public readonly PDO $pdo;

    public function __construct(array $config)
    {
        $this->pdo = new PDO($config['dsn'], $config['user'], $config['password'], [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ]);
        if ($this->pdo->getAttribute(PDO::ATTR_DRIVER_NAME) === 'sqlite') {
            $this->pdo->exec('PRAGMA foreign_keys = ON');
            $this->pdo->exec('PRAGMA busy_timeout = 10000');
        }
    }

    public function isMysql(): bool
    {
        return $this->pdo->getAttribute(PDO::ATTR_DRIVER_NAME) === 'mysql';
    }

    public function migrate(): void
    {
        $sql = file_get_contents(__DIR__ . '/../database/schema.sql');
        $mysql = $this->pdo->getAttribute(PDO::ATTR_DRIVER_NAME) === 'mysql';
        foreach (explode(';', $sql) as $statement) {
            if (trim($statement) !== '') {
                $this->pdo->exec($statement . ($mysql ? ' ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin' : ''));
            }
        }
        if ($mysql) {
            foreach ([
                'ALTER TABLE products MODIFY COLUMN stock_count DOUBLE NOT NULL',
                'ALTER TABLE order_lines MODIFY COLUMN quantity DOUBLE NOT NULL',
            ] as $alter) {
                try {
                    $this->pdo->exec($alter);
                } catch (Throwable) {
                    // Column may already be DOUBLE.
                }
            }
        }
    }

    public function rows(string $sql, array $values = []): array
    {
        $statement = $this->pdo->prepare($sql);
        $statement->execute($values);
        return $statement->fetchAll();
    }

    public function execute(string $sql, array $values = []): int
    {
        $statement = $this->pdo->prepare($sql);
        $statement->execute($values);
        return $statement->rowCount();
    }

    public function transaction(callable $operation): mixed
    {
        $this->pdo->beginTransaction();
        try {
            $result = $operation();
            $this->pdo->commit();
            return $result;
        } catch (Throwable $error) {
            if ($this->pdo->inTransaction()) {
                $this->pdo->rollBack();
            }
            throw $error;
        }
    }
}
