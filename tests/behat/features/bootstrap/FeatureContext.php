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
        // Copy Fixture to guest
        shell_exec("cat ./fixtures/events.sql | vagrant ssh -c 'cat -> /tmp/events.sql'");
        // Import the events.sql into middleware
        shell_exec("vagrant ssh -c 'mysql -uroot -psecret middleware_test < /tmp/events.sql'");
        // Perform an event replay
        shell_exec("vagrant ssh -c '/src/Stepup-Middleware/app/console middleware:event:replay --env=test_event_replay --no-interaction'");
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


    /**
     * @BeforeFeature
     */
    public static function resetFixtures()
    {
        echo shell_exec('echo "beforeFeature"');
    }
}
