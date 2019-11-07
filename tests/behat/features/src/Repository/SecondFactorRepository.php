<?php

namespace Surfnet\StepupBehat\Repository;

use PDO;

/**
 * A poor mans repository, a pdo connection to the test database is established in the constructor
 */
class SecondFactorRepository
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

    public function findNonceById($id)
    {
        $selectFormat = 'SELECT `verification_nonce` FROM `unverified_second_factor` WHERE `id` = :id;';
        $statement = $this->connection->prepare($selectFormat);
        $statement->execute(['id' => $id]);
        $configuration = $statement->fetch();
        return $configuration['verification_nonce'];
    }

    public function getRegistrationCodeByIdentity($identityId)
    {
        $selectFormat = 'SELECT `registration_code` FROM `verified_second_factor` WHERE `identity_id` = :id ORDER BY `registration_requested_at` DESC LIMIT 1;';
        $statement = $this->connection->prepare($selectFormat);
        $statement->execute(['id' => $identityId]);
        $configuration = $statement->fetch();
        return $configuration['registration_code'];
    }

    public function updateRegistrationCode($identityId, $registrationCode)
    {
        $sql = 'UPDATE `verified_second_factor` SET `registration_code` = :code WHERE `identity_id` = :id;';
        $statement = $this->connection->prepare($sql);
        $statement->execute(['code' => $registrationCode, 'id' => $identityId]);
    }
}
