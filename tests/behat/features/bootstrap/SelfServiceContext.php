<?php

use Behat\Behat\Context\Context;
use Behat\Behat\Hook\Scope\BeforeScenarioScope;
use Behat\Behat\Tester\Exception\PendingException;
use Behat\MinkExtension\Context\MinkContext;

class SelfServiceContext implements Context
{
    /**
     * @var \Behat\MinkExtension\Context\MinkContext
     */
    private $minkContext;

    /**
     * @var SecondFactorAuthContext
     */
    private $authContext;

    /**
     * @var string
     */
    private $selfServiceUrl;

    /**
     * @var string
     */
    private $mailCatcherUrl;

    /**
     * @var string
     */
    private $activationCode;

    /**
     * Initializes context.
     */
    public function __construct($selfServiceUrl, $mailCatcherUrl)
    {
        $this->selfServiceUrl = $selfServiceUrl;
        $this->mailCatcherUrl = $mailCatcherUrl;
    }

    /**
     * @BeforeScenario
     */
    public function gatherContexts(BeforeScenarioScope $scope)
    {
        $environment = $scope->getEnvironment();

        $this->minkContext = $environment->getContext(MinkContext::class);
        $this->authContext = $environment->getContext(SecondFactorAuthContext::class);
    }

    /**
     * @Given I am logged in into the selfservice portal
     */
    public function loginIntoSelfService()
    {
        $this->minkContext->visit($this->selfServiceUrl);

        $this->authContext->authenticateWithIdentityProvider();
        $this->authContext->passTroughGatewaySsoAssertionConsumerService();

        $this->minkContext->assertPageAddress('https://selfservice.stepup.example.com/overview');
        $this->minkContext->assertPageContainsText('Registration Portal');
        $this->minkContext->assertPageContainsText('Token Overview');
    }

    /**
     * @When I register a new token
     */
    public function registerNewToken()
    {
        // Click 'add token' on the overview page
        $this->minkContext->clickLink('Add token');

        $this->minkContext->assertPageAddress('/registration/select-token');

        // Select the dummy second factor type
        $this->minkContext->getSession()
            ->getPage()
            ->find('css', '[href="/registration/gssf/dummy/initiate"]')->click();

        $this->minkContext->assertPageAddress('/registration/gssf/dummy/initiate');

        // Start registration
        $this->minkContext->assertPageContainsText('Register with Dummy');
        $this->minkContext->pressButton('Register with Dummy');

        // Register onthe dummy application
        $this->minkContext->assertPageAddress('http://localhost:1234/app_dev.php/registration');
        $this->minkContext->pressButton('Register user');

        // Pass trough GSSP return action
        $this->minkContext->pressButton('Submit');

        // Pass trough gateway
        $this->authContext->passTroughGatewayProxyAssertionConsumerService();

        $this->minkContext->assertPageContainsText('Verify your e-mail');
        $this->minkContext->assertPageContainsText('Check your inbox');
    }

    /**
     * @When I verify my e-mail address
     */
    public function verifyEmailAddress()
    {
        $this->minkContext->visit(
            $this->getEmailVerificationUrl()
        );

        $this->minkContext->printCurrentUrl();
        $this->minkContext->printLastResponse();
        $this->minkContext->assertPageContainsText('Thank you for registering your token.');

        $page  = $this->minkContext->getSession()->getPage();
        $activationCodeCell = $page->find('xpath', '//th[text()="Activation code"]/../td');
        if (!$activationCodeCell) {
            throw new Exception('Could not find a activation code table on the page');
        }

        $this->activationCode = $activationCodeCell->getText();

        if (!preg_match('#[A-Z0-9]{8}#', $this->activationCode)) {
            throw new Exception('Could not find a valid activation code');
        }
    }

    private function getEmailVerificationUrl()
    {
        $message = $this->getLastSentEmail();
        $body = $message->source;

        $body = str_replace("\r", '', $body);
        $body = str_replace("=\n", '', $body);
        $body = str_replace("=3D", '=', $body);

        if (!preg_match('#(https://selfservice.stepup.example.com/verify-email\?n=[a-f0-9]+)#', $body, $matches)) {
            throw new Exception('Unable to find email verification link in message');
        }

        return $matches[1];
    }

    private function getLastSentEmail()
    {
        $response = file_get_contents($this->mailCatcherUrl);

        if (!$response) {
            throw new Exception(
                'Unable to read e-mail - is mailcatcher active?'
            );
        }

        $messages = json_decode($response);
        if (!$messages) {
            throw new Exception(
                'Unable to parse mailcatcher response'
            );
        }

        if (empty($messages)) {
            throw new Exception(
                'No mail received by mailcatcher!'
            );
        }

        $firstMessage = array_pop($messages);

        return $this->getEmailById(
            $firstMessage->id
        );
    }


    private function getEmailById($id)
    {
        $response = file_get_contents(
            sprintf(
                '%s/%d.json',
                rtrim($this->mailCatcherUrl, '/'),
                $id
            )
        );

        if (!$response) {
            throw new Exception(
                'Unable to read e-mail message - is mailcatcher active?'
            );
        }

        $message = json_decode($response);
        if (!$message) {
            throw new Exception(
                'Unable to parse mailcatcher response for single message'
            );
        }

        return $message;
    }
}
