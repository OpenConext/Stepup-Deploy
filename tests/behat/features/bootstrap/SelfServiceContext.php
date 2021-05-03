<?php

use Behat\Behat\Context\Context;
use Behat\Behat\Hook\Scope\BeforeScenarioScope;
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
     * @var string The activation code used to vet the second factor in RA (used in RaContext)
     */
    private $activationCode;

    /**
     * @var string The UUID that identifies the verified second factor (used in RaContext)
     */
    private $verifiedSecondFactorId;

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

        $this->minkContext->assertPageContainsText('Registration Portal');
    }

    /**
     * @Given /^I am logged in into the selfservice portal as "([^"]*)"$/
     */
    public function iAmLoggedInIntoTheSelfServicePortalAs($userName)
    {
        // We visit the Self Service location url
        $this->minkContext->visit($this->selfServiceUrl);
        $this->authContext->authenticateWithIdentityProviderFor($userName);
        $this->authContext->passTroughGatewaySsoAssertionConsumerService();
        $this->iSwitchLocaleTo('English');
        $this->minkContext->assertPageContainsText('Registration Portal');
    }

    /**
     * @When I register a new Dummy token
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
     * @When I register a new SMS token
     */
    public function registerNewSmsToken()
    {
        $this->minkContext->assertPageAddress('/registration/select-token');

        // Select the SMS second factor type
        $this->minkContext->getSession()
            ->getPage()
            ->find('css', '[href="/registration/sms/send-challenge"]')->click();

        $this->minkContext->assertPageAddress('/registration/sms/send-challenge');
        // Start registration
        $this->minkContext->assertPageContainsText('Send SMS code');
        $this->minkContext->fillField('ss_send_sms_challenge_subscriber', '612345678');
        $this->minkContext->pressButton('Send code');
        // Now we should be on the prove possession page where we enter our OTP
        $this->minkContext->assertPageAddress('/registration/sms/prove-possession');
        $this->minkContext->assertPageContainsText('Enter SMS code');
        $this->minkContext->fillField('ss_verify_sms_challenge_challenge', '999');

        $this->minkContext->pressButton('Verify');

        ## And we should now be on the mail verification page
        $this->minkContext->assertPageContainsText('Verify your e-mail');
        $this->minkContext->assertPageContainsText('Check your inbox');
    }

    /**
     * @When I self-vet a new SMS token with my Yubikey token

     */
    public function selfVetNewSmsToken()
    {
        $this->minkContext->visit($this->selfServiceUrl);
        $this->minkContext->assertPageAddress('/overview');

        $this->minkContext->assertPageContainsText('The following tokens are registered for your account');
        $this->minkContext->assertPageContainsText('Yubikey');

        $this->minkContext->visit('/registration/select-token');

        // Select the sms second factor type
        $this->minkContext->getSession()
            ->getPage()
            ->find('css', '[href="/registration/sms/send-challenge"]')->click();
        $this->minkContext->assertPageAddress('/registration/sms/send-challenge');

        // Start registration
        $this->minkContext->assertPageContainsText('Send SMS code');
        $this->minkContext->fillField('ss_send_sms_challenge_subscriber', '612345678');
        $this->minkContext->pressButton('Send code');

        $this->minkContext->assertPageContainsText('Please validate that you can receive SMS messages on this phone');
        $this->minkContext->fillField('ss_verify_sms_challenge_challenge', '999');
        $this->minkContext->pressButton('Verify');

        $this->minkContext->visit(
            $this->getEmailVerificationUrl()
        );
        // Now we should be on the choose vetting page
        $this->minkContext->assertPageContainsText('Use your existing token');
        $page = $this->minkContext->getSession()->getPage();
        $form = $page->find('css', 'form[action$="self-vet"]');
        $form->submit();
        $this->minkContext->pressButton('Submit');
        $this->authContext->authenticateUserYubikeyInGateway();
        $this->minkContext->printLastResponse(); die;


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
        $this->minkContext->assertPageContainsText('Thank you for registering your token.');

        $page  = $this->minkContext->getSession()->getPage();
        $activationCodeCell = $page->find('xpath', '//th[text()="Activation code"]/../td');
        if (!$activationCodeCell) {
            throw new Exception('Could not find a activation code table on the page');
        }

        $url  = $this->minkContext->getSession()->getCurrentUrl();
        $matches = [];
        preg_match('#[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}#', $url, $matches);
        if (empty($matches)) {
            throw new Exception('Could not find a valid second factor verification id in the url');
        }
        $this->activationCode = $activationCodeCell->getText();
        $this->verifiedSecondFactorId = reset($matches);

        if (!preg_match('#[A-Z0-9]{8}#', $this->activationCode)) {
            throw new Exception('Could not find a valid activation code');
        }
    }

    /**
     * @Given /^I visit the "([^"]*)" page in the selfservice portal$/
     */
    public function iVisitAPageInTheSelfServiceEnvironment($uri)
    {
        // We visit the SS location url
        $this->minkContext->visit($this->selfServiceUrl.'/'.$uri);
    }

    private function iSwitchLocaleTo(string $newLocale): void
    {
        $page = $this->minkContext->getSession()->getPage();
        $selectElement = $page->find('css', '#stepup_switch_locale_locale');
        $selectElement->selectOption($newLocale);
        $form = $page->find('css', 'form[name="stepup_switch_locale"]');
        $form->submit();
    }

    private function getEmailVerificationUrl()
    {
        $body = $this->getLastSentEmail();
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
                '%s/%d.html',
                rtrim($this->mailCatcherUrl, '/'),
                $id
            )
        );

        if (!$response) {
            throw new Exception(
                'Unable to read e-mail message - is mailcatcher active?'
            );
        }

        return $response;
    }

    /**
     * @return string
     */
    public function getActivationCode()
    {
        return $this->activationCode;
    }

    /**
     * @return string
     */
    public function getVerifiedSecondFactorId()
    {
        return $this->verifiedSecondFactorId;
    }
}
