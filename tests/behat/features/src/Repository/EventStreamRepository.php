<?php

namespace Surfnet\StepupBehat\Repository;

use PDO;

/**
 * A poor mans repository, a pdo connection to the test database is established in the constructor
 */
class EventStreamRepository
{
    /**
     * @var PDO
     */
    private $connection;

    public function __construct()
    {
        // Settings
        $dbUser = 'root';
        $dbPassword = 'password';
        $dbName = 'middleware_test';
        $dsn = 'mysql:host=127.0.0.1;dbname=%s';
        // Open a PDO connection
        $this->connection = new PDO(sprintf($dsn, $dbName), $dbUser, $dbPassword);
    }

    public function findLatestByEventName(string $name): array
    {
        $sql = 'SELECT * FROM `event_stream` WHERE type LIKE CONCAT("%", :name) ORDER BY recorded_on DESC LIMIT 1';
        $statement = $this->connection->exec($sql);
        $statement->execute(['name' => $name]);
        return $statement->fetch();
    }
}
