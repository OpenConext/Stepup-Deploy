<?php

use Behat\Behat\Context\Context;
use Behat\Behat\Hook\Scope\BeforeScenarioScope;
use Behat\Mink\Exception\ElementNotFoundException;
use Behat\MinkExtension\Context\MinkContext;

class SecondFactorAuthContext implements Context
{
    const SSO_IDP = 'https://gateway.stepup.example.com/authentication/metadata';
    const SFO_IDP = 'https://gateway.stepup.example.com/second-factor-only/metadata';
    const SSO_SP = 'default-sp';
    const SFO_SP = 'second-sp';
    const TEST_NAMEID = 'urn:collab:person:institution-a.example.com:jane-a1';

    /**
     * @var \Behat\MinkExtension\Context\MinkContext
     */
    private $minkContext;

    /**
     * @var string
     */
    private $spTestUrl;

    /**
     * @var string
     */
    private $activeIdp;

    /**
     * @var string
     */
    private $activeSp;

    /**
     * @var int
     */
    private $requiredLoa;

    /**
     * @var string
     */
    private $storedAuthnRequest;
    /**
     * @var string
     */
    private $storedChallengeCode;

    /**
     * Initializes context.
     */
    public function __construct($spTestUrl)
    {
        $this->spTestUrl = $spTestUrl;
    }

    /**
     * @BeforeScenario
     */
    public function gatherContexts(BeforeScenarioScope $scope)
    {
        $environment = $scope->getEnvironment();

        $this->minkContext = $environment->getContext(MinkContext::class);
    }

    /**
     * @Given a service provider configured for second-factor-only
     */
    public function configureServiceProviderForSecondFactorOnly()
    {
        $this->activeIdp = self::SFO_IDP;
        $this->activeSp = self::SFO_SP;
        $this->requiredLoa = 2;
    }

    /**
     * @Given a service provider configured for single-signon
     */
    public function configureServiceProviderForSingleSignOn()
    {
        $this->activeIdp = self::SSO_IDP;
        $this->activeSp = self::SSO_SP;
        $this->requiredLoa = 2;
    }

    /**
     * @When I visit the service provider
     */
    public function visitServiceProvider()
    {
        $this->minkContext->visit($this->spTestUrl);

        $this->minkContext->fillField('idp', $this->activeIdp);
        $this->minkContext->fillField('sp', $this->activeSp);
        $this->minkContext->fillField('loa', $this->requiredLoa);

        if ($this->activeIdp === self::SFO_IDP) {
            $this->minkContext->fillField('subject', self::TEST_NAMEID);
        }
        $this->minkContext->pressButton('Login');
    }

    private function fillField($session, $field, $value)
    {
        $field = $this->fixStepArgument($field);
        $value = $this->fixStepArgument($value);
        $this->minkContext->getSession($session)->getPage()->fillField($field, $value);
    }
    private function fixStepArgument($argument)
    {
        return str_replace('\\"', '"', $argument);
    }

    /**
     * @Given the service provider requires no second factor
     */
    public function setImplicitLoaOnServiceProvider()
    {
        $this->requiredLoa = 1;
    }

    /**
     * @When I verify the :arg1 second factor
     */
    public function verifySpecifiedSecondFactor($tokenType, $smsChallenge = null)
    {
        switch ($tokenType){
            case "sms":
                // Pass through acs
                $this->minkContext->pressButton('Submit');
                $this->authenticateUserSmsInGateway($smsChallenge);
                break;
            case "yubikey":
                $this->authenticateUserYubikeyInGateway();
                break;
            case "dummy":
                $this->authenticateUserInDummyGsspApplication();
                break;
            default:
                throw new Exception(
                    sprintf(
                        'Second factor type of "%s" is not yet supported in the tests.',
                        $tokenType
                    )
                );
                break;
        }
    }

    /**
     * @When I verify the Yubikey second factor
     */
    public function verifyYuikeySecondFactor()
    {
        $this->authenticateUserYubikeyInGateway();
    }

    /**
     * @When I cancel the :arg1 second factor authentication
     */
    public function cancelSecondFactorAuthentication($tokenType)
    {
        switch ($tokenType){
            case "yubikey":
                $this->cancelYubikeyAuthentication();
                break;
            case "dummy":
                $this->cancelAuthenticationInDummyGsspApplication();
                break;
            default:
                throw new Exception(
                    sprintf(
                        'Second factor type of "%s" is not yet supported in the tests.',
                        $tokenType
                    )
                );
                break;
        }
    }

    /**
     * @Then second factor authentication is not initiated
     */
    public function secondFactorAuthenticationIsNotInitiated()
    {
        $this->passTroughGatewaySsoAssertionConsumerService();
    }

    public function selectDummySecondFactorOnTokenSelectionScreen()
    {
        $this->minkContext->pressButton('gateway_choose_second_factor_choose_dummy');
    }

    public function selectYubikeySecondFactorOnTokenSelectionScreen()
    {
        $this->minkContext->pressButton('gateway_choose_second_factor_choose_yubikey');
    }

    public function authenticateUserInDummyGsspApplication()
    {
        $this->minkContext->assertPageAddress('http://localhost:1234/authentication');

        // Trigger the dummy authentication action.
        $this->minkContext->pressButton('Authenticate user');

        // Pass through the 'return to sp' redirection page.
        $this->minkContext->pressButton('Submit');
    }

    public function authenticateUserYubikeyInGateway()
    {
        // try SFO retry on SSO, might be better to create a new test method instead..
        try {
            $this->minkContext->assertPageAddress('https://gateway.stepup.example.com/verify-second-factor/sfo/yubikey');
        } catch (Exception $e) {
            $this->minkContext->assertPageAddress('https://gateway.stepup.example.com/verify-second-factor/sso/yubikey');
        }
        // Give an OTP
        $this->minkContext->fillField('gateway_verify_yubikey_otp_otp', 'ccccccdhgrbtucnfhrhltvfkchlnnrndcbnfnnljjdgf');
        // Simulate the enter press the yubikey otp generator
        $form = $this->minkContext->getSession()->getPage()->find('css', '[id="gateway_verify_yubikey_otp_otp"]');
        if (!$form) {
            throw new ElementNotFoundException('Yubikey OTP Submit form could not be found on the page');
        }
        $this->minkContext->pressButton('gateway_verify_yubikey_otp_submit');
        // Pass through the 'return to sp' redirection page.
        $this->minkContext->pressButton('Submit');
    }

    private function debugOut($arg = null)
    {
        if ($arg !== null) {
            var_dump($arg);
        }
        echo $this->minkContext->getSession()->getCurrentUrl();
        echo PHP_EOL . PHP_EOL;
        die($this->minkContext->getSession()->getPage()->getHtml());
    }

    public function authenticateUserSmsInGateway(string $challenge)
    {
        $this->minkContext->assertPageAddress('https://gateway.stepup.example.com/verify-second-factor/sms/verify-challenge');
        // Fill the challenge
        $this->minkContext->fillField('gateway_verify_sms_challenge_challenge', $challenge);
        // Submit the form
        $this->minkContext->pressButton('Verify code');
        $this->minkContext->assertResponseNotContains('stepup.verify_possession_of_phone_command.challenge.may_not_be_empty');
    }

    public function cancelAuthenticationInDummyGsspApplication()
    {
        $this->minkContext->assertPageAddress('http://localhost:1234/authentication');

        // Cancel the dummy authentication action.
        $this->minkContext->pressButton('Return authentication failed');

        // Pass through the 'return to sp' redirection page.
        $this->minkContext->pressButton('Submit');
    }

    public function cancelYubikeyAuthentication()
    {
        // try SFO retry on SSO, might be better to create a new test method instead..
        try {
            $this->minkContext->assertPageAddress('https://gateway.stepup.example.com/verify-second-factor/sfo/yubikey');
        } catch (Exception $e) {
            $this->minkContext->assertPageAddress('https://gateway.stepup.example.com/verify-second-factor/sso/yubikey');
        }
        // Cancel the yubikey authentication action.
        $this->minkContext->pressButton('Cancel');

        // Pass through the 'return to sp' redirection page.
        $this->minkContext->pressButton('Submit');
    }

    public function passTroughGatewaySsoAssertionConsumerService()
    {
        $this->minkContext->assertPageAddress('https://gateway.stepup.example.com/authentication/consume-assertion');

        $this->minkContext->pressButton('Submit');
    }

    public function passTroughGatewayProxyAssertionConsumerService()
    {
        $this->minkContext->assertPageAddress('https://gateway.stepup.example.com/gssp/dummy/consume-assertion');

        $this->minkContext->pressButton('Submit');
    }

    /**
     * @When I authenticate with the identity provider
     */
    public function authenticateWithIdentityProvider()
    {
        $this->minkContext->assertPageAddress('https://ssp.stepup.example.com/module.php/core/loginuserpass.php');

        $this->minkContext->fillField('username', 'joe-a1');
        $this->minkContext->fillField('password', 'joe-a1');

        $this->minkContext->pressButton('Login');

        $this->passTroughIdentityProviderAssertionConsumerService();
    }

    /**
     * @When I authenticate as :arg1 with the identity provider
     */
    public function authenticateWithIdentityProviderFor($userName)
    {
        $this->minkContext->assertPageAddress('https://ssp.stepup.example.com/module.php/core/loginuserpass.php');

        $this->minkContext->fillField('username', $userName);
        $this->minkContext->fillField('password', $userName);

        $this->minkContext->pressButton('Login');
        $this->passTroughIdentityProviderAssertionConsumerService();
    }

    private function passTroughIdentityProviderAssertionConsumerService()
    {
        $this->minkContext->assertPageAddress('https://ssp.stepup.example.com/module.php/core/loginuserpass.php');
        $this->minkContext->assertPageNotContainsText('Incorrect username or password');
        $this->minkContext->pressButton('Submit');
    }

    /**
     * @Then I am logged on the service provider
     */
    public function assertLoggedInOnServiceProvider()
    {
        $this->minkContext->assertPageAddress('https://ssp.stepup.example.com/sp.php');

        $this->minkContext->assertPageContainsText(
            sprintf('You are logged in to SP')
        );
    }

    /**
     * @Then I see an error at the service provider
     */
    public function assertErrorAtServiceProvider()
    {
        $this->minkContext->assertPageAddress('https://ssp.stepup.example.com/module.php/saml/sp/saml2-acs.php/default-sp');

        $this->minkContext->assertPageContainsText(
            sprintf('Unhandled exception')
        );

        $this->minkContext->assertPageNotContainsText(
            sprintf('You are logged in to SP')
        );
    }

    /**
     * @When I prepare an SFO authentication as :arg1
     */
    public function prepareSfoAuthentication($nameId)
    {
        $this->minkContext->getSession('second')->visit($this->spTestUrl);

        $this->fillField('second', 'idp', $this->activeIdp);
        $this->fillField('second','sp', $this->activeSp);
        $this->fillField('second','loa', $this->requiredLoa);
        $this->fillField('second', 'subject', $nameId);
    }

    /**
     * @Given I start and intercept the SFO authentication
     */
    public function iStartASMSSFOAuthentication()
    {
        // To intercept the AuthNRequest, instruct the 'browser' not to auto-follow redirects
        $client = $this->minkContext->getSession('second')->getDriver()->getClient();
        $client->followRedirects(false);
        $this->minkContext->getSession('second')->getPage()->pressButton('Login');
        // Jump from SSP SP to Gateway (we are interested in that AR)
        $client->followRedirect();
        // Catch the Url containing he AuthNRequest, removing the trailing slash
        $this->storedAuthnRequest = $this->minkContext->getSession('second')->getCurrentUrl();
        // And back to normal
        $client->followRedirects(true);
    }

    /**
     * @Given I start the stored SFO session in the victims session remembering the challenge for :arg1
     */
    public function victimizeTheStoredSFORequest($phoneNumber)
    {
        if ($this->storedAuthnRequest === null) {
            throw new RuntimeException('There is no stored authentication request. First run step definition: "I start and intercept a SMS SFO authentication"');
        }
        $this->minkContext->visit($this->storedAuthnRequest);
        $this->minkContext->assertPageAddress('https://gateway.stepup.example.com/verify-second-factor/sms/verify-challenge?authenticationMode=sfo');
        $this->storedChallengeCode[$phoneNumber] = $this->fetchSmsChallengeFromCookie($phoneNumber);
    }

    /**
     * @Given I use the stored SMS verification code for :arg1
     */
    public function iUseTheStoredVerificationCode($phoneNumber)
    {
        if (!isset($this->storedChallengeCode[$phoneNumber])) {
            throw new RuntimeException('There is no stored SMS challenge available for this phone number.');
        }
        $this->authenticateUserSmsInGateway($this->storedChallengeCode[$phoneNumber]);
    }

    private function fetchSmsChallengeFromCookie($phoneNumber): string
    {
        $cookies = $this->minkContext
            ->getSession()
            ->getDriver()
            ->getClient()
            ->getCookieJar()
            ->all();
        $expectedCookieName = sprintf("%s%s", 'smoketest-sms-service-', $phoneNumber);
        $bodyPattern = '/^Your.SMS.code:.([A-Z-0-9]+)$/';
        foreach ($cookies as $cookie) {
            if ($cookie->getName() === $expectedCookieName) {
                $bodyMatches = [];
                preg_match($bodyPattern, $cookie->getValue(), $bodyMatches);
                return array_pop($bodyMatches);
            }
        }
        throw new RuntimeException('SMS verification code was not found in smoketest cookie');
    }

    /**
     * @Then I start an SMS SSO session for :arg1 with verification code for :arg2
     */
    public function iStartAnSmsSSOSessionFor($userName, $phoneNumber)
    {
        $this->configureServiceProviderForSingleSignOn();
        $this->visitServiceProvider();
        // Pass through Gateway (already authenticated)
        $this->minkContext->pressButton('Submit');
        // Choose SMS token on WAYG
        $this->minkContext->pressButton('gateway_choose_second_factor[choose_sms]');
    }

    /**
     * @Then /^The verification code is invalid$/
     */
    public function theVerificationCodeIsInvalid()
    {
        $this->minkContext->assertResponseContains('This code is not correct. Please try again or request a new code.');
    }
}
