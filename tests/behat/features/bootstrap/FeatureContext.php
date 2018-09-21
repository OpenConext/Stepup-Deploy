<?php

use Behat\Behat\Context\Context;
use Behat\Behat\Hook\Scope\BeforeScenarioScope;
use Behat\MinkExtension\Context\MinkContext;

class FeatureContext implements Context
{

    /**
     * @var \Behat\MinkExtension\Context\MinkContext
     */
    private $minkContext;

    /**
     * @BeforeSuite
     */
    public static function setupDatabase($scope)
    {
        // Generate test databases
        shell_exec("/src/Stepup-Middleware/app/console doctrine:schema:drop --env=smoketest --force");
        shell_exec("/src/Stepup-Gateway/app/console doctrine:schema:drop --env=test --force");
        shell_exec("/src/Stepup-Middleware/app/console doctrine:schema:create --env=smoketest");
        shell_exec("/src/Stepup-Gateway/app/console doctrine:schema:create --env=test");
        // Import the events.sql into middleware
        shell_exec("mysql -uroot -ppassword middleware_test < ./fixtures/events.sql");
        // Perform an event replay
        shell_exec("/src/Stepup-Middleware/app/console middleware:event:replay --env=smoketest_event_replay --no-interaction");
    }

    /**
     * @BeforeScenario
     */
    public function gatherContexts(BeforeScenarioScope $scope)
    {
        $environment = $scope->getEnvironment();

        $this->minkContext = $environment->getContext(MinkContext::class);
        // Set the testcookie, effectively putting the Stepup suite in test mode
        $this->minkContext->getSession()->setCookie('testcookie', 'testcookie');
    }
}
