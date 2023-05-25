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
     * @var string The activation code used to vet the second factor in RA (used in RaContext)
     */
    private $activationCode;

    /**
     * @var string The UUID that identifies the verified second factor (used in RaContext)
     */
    private $verifiedSecondFactorId;

    private $safeStoreRecoveryToken = '';

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
        $this->registerAndVerifySMSToken();
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

        $this->minkContext->assertPageContainsText('Enter the code that was sent to your phone');
        $this->minkContext->fillField('ss_verify_sms_challenge_challenge', '999');
        $this->minkContext->pressButton('Verify');

        // Now we should be on the choose vetting page
        $this->minkContext->assertPageContainsText('Use your existing token');
        $page = $this->minkContext->getSession()->getPage();
        $form = $page->find('css', 'form[action$="self-vet"]');
        $form->submit();
        $this->minkContext->pressButton('Submit');
        $this->authContext->authenticateUserYubikeyInGateway();
    }

    /**
     * @Given start registration of a self-asserted ":tokenType" token
     */
    public function startRegistrationOfASelfAssertedToken(string $tokenType)
    {
        $this->minkContext->assertPageAddress('/registration/select-token');
        switch ($tokenType) {
            case 'SMS':
                $this->registerAndVerifySMSToken();
                break;
            case 'Yubikey':
                $this->registerAndVerifyYubikeyToken();
                break;
            default:
                throw new PendingException();
        }
        $page = $this->minkContext->getSession()->getPage();
        $form = $page->find('css', 'form[action$="self-asserted-token-registration"]');
        $form->submit();
    }

    private function registerAndVerifyYubikeyToken()
    {
        $this->minkContext->getSession()
            ->getPage()
            ->find('css', '[href="/registration/yubikey/prove-possession"]')->click();
        $this->minkContext->assertPageAddress('/registration/yubikey/prove-possession');

        // Start registration
        $this->minkContext->assertPageContainsText('Link your YubiKey');
        $this->minkContext->fillField('ss_prove_yubikey_possession_otp', 'vviveikvgbguhrfthjuciuinkiregvdfrknjtukbrbve');
        $page = $this->minkContext->getSession()->getPage();
        $form = $page->find('css', 'form[name="ss_prove_yubikey_possession"]');
        $form->submit();
    }

    private function registerAndVerifySMSToken()
    {
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
    }

    /**
     * @Given create a ":tokenType" recovery token
     */
    public function createARecoveryToken(string $tokenType)
    {
        $this->minkContext->assertPageContainsText('Add recovery method');
        $page = $this->minkContext->getSession()->getPage();

        switch ($tokenType) {
            case 'safe-store':
                $form = $page->find('css', 'form[action$="safe-store"]');
                $form->submit();

                $this->minkContext->assertPageContainsText('The recovery code below will only be displayed once. Keep this recovery code somewhere safe in case you need it in the future');

                $this->safeStoreRecoveryToken = $this->extractSafeStoreSecret();
                $page = $this->minkContext->getSession()->getPage();
                $form = $page->find('css', 'form[name="ss_promise_recovery_token_possession"]');
                $form->checkField('ss_promise_recovery_token_possession_promisedPossession');
                $form->submit();
                break;
            case 'SMS':
                $form = $page->find('css', 'form[action$="sms"]');
                $form->submit();
                $this->minkContext->assertPageContainsText('Register recovery phone number');
                $this->minkContext->fillField('ss_send_sms_challenge_subscriber', '612345678');
                $this->minkContext->pressButton('Send code');

                $this->minkContext->assertPageContainsText('Enter the code that was sent to your phone');
                $this->minkContext->fillField('ss_verify_sms_challenge_challenge', '123132');
                $page = $this->minkContext->getSession()->getPage();
                $form = $page->find('css', 'form[name="ss_verify_sms_challenge"]');
                $form->submit();
                break;
            default:
                throw new PendingException();
        }
    }

    private function extractSafeStoreSecret(): string
    {
        $page = $this->minkContext->getSession()->getPage();
        return $page->find('css', 'p.password')->getText();
    }

    /**
     * @Then I should see a LoA ":loaLevel" ":tokenType" token
     */
    public function iShouldSeeALoaToken(float $loaLevel, string $tokenType)
    {
        $this->minkContext->assertPageContainsText('The following tokens are registered for your account.');
        switch ($tokenType) {
            case "SMS":
                $this->minkContext->assertPageContainsText('SMS');
                $this->minkContext->assertPageContainsText('+31 (0) 612345678');

                break;
            case "Yubikey":
                $this->minkContext->assertPageContainsText('Yubikey');
                $this->minkContext->assertPageContainsText('280921859117406');
                break;
            default:
                throw new PendingException();
        }

        $loaOnPage = $this->calculateLoa();
        if ($loaOnPage !== $loaLevel) {
            throw new Exception(
                sprintf(
                    'The LoA on the page (%.1F) did not match the expected LoA (%.1F)',
                    $loaOnPage,
                    $loaLevel
                )
            );
        }
    }

    private function calculateLoa(): float
    {
        $page = $this->minkContext->getSession()->getPage();
        // Iffy logic, when more than one tokens are present on page this will probably stop working or only work for the first token.
        $starRatingComponent = $page->find('css', 'span.loa-star-rating');
        $openStarsCount = count($starRatingComponent->findAll('css', 'img.star-open'));
        $halfStarsCount = count($starRatingComponent->findAll('css', 'img.star-half'));
        $rating = 3 - $openStarsCount;
        if ($halfStarsCount === 1 && $openStarsCount === 1) {
            return 1.5;
        }
        if ($halfStarsCount === 1) {
            $rating += 0.5;
        }
        return (float) $rating;
    }

    /**
     * @Then I should see a ":tokenType" recovery token
     */
    public function iShouldSeeARecoveryToken($tokenType)
    {
        $this->minkContext->assertPageContainsText('Recovery methods');
        switch ($tokenType) {
            case "safe-store":
                $this->minkContext->assertPageContainsText('Recovery code');
                break;
            case "SMS":
                $this->minkContext->assertPageContainsText('Recovery phone number');
                $this->minkContext->assertPageContainsText('+31 (0) 612345678');
                break;
            default:
                throw new PendingException();
        }
    }

    /**
     * This step simply clicks the recovery-token/delete link. If more than one exist on page, this might not work.
     * @Given I revoke my :tokenType token
     */
    public function iRevokeMyToken($tokenType)
    {
        $page = $this->minkContext->getSession()->getPage();
        $revokeLink = $page->find('css', 'a.btn-warning[href^="/second-factor/vetted/"]');
        $revokeLink->click();
        $this->minkContext->assertPageContainsText('Remove token');
        $this->minkContext->assertPageContainsText('You are about to remove the following token');
        $page = $this->minkContext->getSession()->getPage();
        $form = $page->find('css', 'form[name="ss_revoke_second_factor"]');
        $form->submit();
    }

    /**
     * @Then I register a :tokenType token using the :recoveryTokenType recovery token
     */
    public function iRegisterMyTokenUsingTheRecoveryToken($tokenType, $recoveryTokenType)
    {
        $this->minkContext->clickLink('Add token');

        switch ($tokenType) {
            case 'SMS':
                $this->registerAndVerifySMSToken();
                break;
            case 'Yubikey':
                $this->registerAndVerifyYubikeyToken();
                break;
            default:
                throw new PendingException();
        }

        // Choose SAT vetting type
        $page = $this->minkContext->getSession()->getPage();
        $form = $page->find('css', 'form[action$="self-asserted-token-registration"]');
        $form->submit();

        switch ($recoveryTokenType) {
            case 'safe-store':
                $this->minkContext->assertPageContainsText('Activate using your recovery code');
                $page = $this->minkContext->getSession()->getPage();
                $form = $page->find('css', 'form[name="ss_authenticate_safe_store"]');
                $form->fillField('ss_authenticate_safe_store_secret', $this->safeStoreRecoveryToken);
                $form->submit();
                break;
            case 'SMS':
                $this->minkContext->assertPageContainsText('Enter the code that was sent to your phone');
                $this->minkContext->fillField('ss_verify_sms_challenge_challenge', '999');
                $this->minkContext->pressButton('Verify');
                break;
            default:
                throw new PendingException();
        }
    }

    /**
     * @Given I register a ":tokenType" recovery token
     */
    public function iRegisterARecoveryToken(string $tokenType)
    {
        $this->minkContext->assertPageContainsText('Always make sure you have at least one recovery method');
        switch ($tokenType) {
            case 'safe-store':
                $this->minkContext->clickLink('Add recovery method');
                $page = $this->minkContext->getSession()->getPage();
                $form = $page->find('css', 'form[action$="/recovery-token/create-safe-store"]');
                $form->submit();

                // Authentication step to ensure the identity is in posession of the second factor token it is
                // registering a Recovery token for.
                $this->minkContext->pressButton('Submit');
                $this->minkContext->assertPageContainsText('Your YubiKey-code:');
                $this->minkContext->fillField('gateway_verify_yubikey_otp_otp', 'vviveikvgbguhrfthjuciuinkiregvdfrknjtukbrbve');
                $page = $this->minkContext->getSession()->getPage();
                $form = $page->find('css', 'form[name="gateway_verify_yubikey_otp"]');
                $form->submit();
                // Pass through gateway back to the selfservice
                $this->minkContext->pressButton('Submit');

                $this->minkContext->assertPageContainsText('The recovery code below will only be displayed once. Keep this recovery code somewhere safe in case you need it in the future');

                $page = $this->minkContext->getSession()->getPage();
                $form = $page->find('css', 'form[name="ss_promise_recovery_token_possession"]');
                $form->checkField('ss_promise_recovery_token_possession_promisedPossession');
                $form->submit();
                break;
            default:
                throw new PendingException();
        }
    }

    /**
     * @Given /^I try to self\-vet a new Yubikey token with my SMS token$/
     */
    public function iTryToSelfVetANewYubikeyTokenWithMySMSToken()
    {
        $this->minkContext->visit($this->selfServiceUrl);
        $this->minkContext->assertPageAddress('/overview');

        $this->minkContext->assertPageContainsText('The following tokens are registered for your account');
        $this->minkContext->assertPageContainsText('Yubikey');

        $this->minkContext->visit('/registration/select-token');

        // Select the sms second factor type
        $this->minkContext->getSession()
            ->getPage()
            ->find('css', '[href="/registration/yubikey/prove-possession"]')->click();
        $this->minkContext->assertPageAddress('/registration/yubikey/prove-possession');

        // Start registration
        $this->minkContext->assertPageContainsText('Link your YubiKey');
        $this->minkContext->fillField('ss_send_sms_challenge_subscriber', '612345678');
        $this->minkContext->pressButton('Send code');

        $this->minkContext->assertPageContainsText('Please validate that you can receive SMS messages on this phone');
        $this->minkContext->fillField('ss_prove_yubikey_possession_otp', 'scvcb234cv3234213abas41');
        $page = $this->minkContext->getSession()->getPage();
        $form = $page->find('css', 'form[name="ss_prove_yubikey_possession"]');
        $form->submit();

        $this->minkContext->visit(
            $this->getEmailVerificationUrl()
        );
        $this->verifyEmailAddress();
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
