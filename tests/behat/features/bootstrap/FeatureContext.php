<?php

use Behat\Behat\Context\Context;
use Behat\Behat\Hook\Scope\BeforeScenarioScope;
use Behat\MinkExtension\Context\MinkContext;

class FeatureContext implements Context
{
    /**
     * @BeforeSuite
     */
    public static function setupDatabase()
    {
        //echo shell_exec('vagrant ssh -c "/src/Stepup-Gateway/app/console cache:clear --env=test"');

        // Drop existing schemas
        echo shell_exec('vagrant ssh -c "/src/Stepup-Middleware/app/console app/console doctrine:schema:drop --env=test --force -q"');
        echo shell_exec('vagrant ssh -c "/src/Stepup-Gateway/app/console app/console doctrine:schema:drop --env=test --force -q"');

        // Bootstrap the test databases
        echo shell_exec('vagrant ssh -c "/src/Stepup-Middleware/app/console middleware:migrations:migrate --env=test"');
        echo shell_exec('vagrant ssh -c "echo Y | /src/Stepup-Gateway/app/console php app/console u2f:migrations:migrate --env=test"');
    }

    /**
     * @BeforeFeature
     */
    public static function resetFixtures()
    {
        echo shell_exec('echo "beforeFeature"');
    }
}
