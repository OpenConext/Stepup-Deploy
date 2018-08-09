<?php

use Behat\Behat\Context\Context;
use Behat\Behat\Hook\Scope\BeforeScenarioScope;
use Behat\Behat\Tester\Exception\PendingException;
use Behat\MinkExtension\Context\MinkContext;
use Behat\MinkExtension\Context\RawMinkContext;

class RaContext implements Context
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
     * @var SelfServiceContext
     */
    private $selfServiceContext;

    /**
     * @var string
     */
    private $raUrl;

    /**
     * @var RawMinkContext
     */
    private $session;

    /**
     * Initializes context.
     */
    public function __construct($raUrl)
    {
        $this->raUrl = $raUrl;
    }

    /**
     * @BeforeScenario
     */
    public function gatherContexts(BeforeScenarioScope $scope)
    {
        $environment = $scope->getEnvironment();

        $this->minkContext = $environment->getContext(MinkContext::class);
        $this->authContext = $environment->getContext(SecondFactorAuthContext::class);
        $this->selfServiceContext = $environment->getContext(SelfServiceContext::class);
    }

    /**
     * @Given /^I vet my second factor at the information desk$/
     */
    public function iVetMySecondFactorAtTheInformationDesk()
    {
        // The ra session is used to vet the token
        $this->minkContext->getMink()->setDefaultSessionName('ra');

        // We visit the RA location url
        $this->minkContext->visit($this->raUrl);

        $this->adminLogsInToRa();
        $this->findsTokenForActivation();
        $this->userProvesPosessionOfDummyToken();
        $this->adminVerifiesUserIdentity();
        $this->vettingProcessIsCompleted();

        // Switch back to the default session
        $this->minkContext->getMink()->setDefaultSessionName('default');
    }

    private function adminLogsInToRa()
    {
        // The admin user logs in and gives a Yubikey second factor
        $this->authContext->authenticateWithIdentityProviderAsAdmin();
        $this->authContext->verifyYuikeySecondFactor();

        // We are now on the RA homepage
        $this->minkContext->assertPageAddress('https://ra.stepup.example.com');
        $this->minkContext->assertPageContainsText('RA Management Portal');
        $this->minkContext->assertPageContainsText('Token activation');
    }

    public function findsTokenForActivation()
    {
        // The activation token was previously set on the SP context, and can be retrieved here.
        $activationCode = $this->selfServiceContext->getActivationCode();
        $this->minkContext->fillField('ra_start_vetting_procedure_registrationCode', $activationCode);
        $this->minkContext->pressButton('Search');
    }

    private function userProvesPosessionOfDummyToken()
    {
        $vettingProcedureUrl = 'https://ra.stepup.example.com/vetting-procedure/%s/gssf/dummy/initiate-verification';

        $this->minkContext->assertPageAddress(
            sprintf(
                $vettingProcedureUrl,
                $this->selfServiceContext->getVerifiedSecondFactorId()
            )
        );

        // Press the initiate vetting procedure button in the search results
        $this->minkContext->pressButton('ra_initiate_gssf_submit');
        // Press the Authenticate button on the Dummy authentication page
        $this->minkContext->pressButton('button_authenticate');
        // Pass through the Dummy Gssp redirection page.
        $this->minkContext->pressButton('Submit');
        // Pass through the 'return to sp' redirection page.
        $this->minkContext->pressButton('Submit');
    }

    private function adminVerifiesUserIdentity()
    {
        $vettingProcedureUrl = 'https://ra.stepup.example.com/vetting-procedure/%s/verify-identity';

        $this->minkContext->assertPageAddress(
            sprintf(
                $vettingProcedureUrl,
                $this->selfServiceContext->getVerifiedSecondFactorId()
            )
        );
        $this->minkContext->fillField('ra_verify_identity_documentNumber', '654321');
        $this->minkContext->checkOption('ra_verify_identity_identityVerified');
        $this->minkContext->pressButton('Verify identity');
    }

    private function vettingProcessIsCompleted()
    {
        $vettingProcedureUrl = 'https://ra.stepup.example.com/vetting-procedure/%s/completed';

        $this->minkContext->assertPageAddress(
            sprintf(
                $vettingProcedureUrl,
                $this->selfServiceContext->getVerifiedSecondFactorId()
            )
        );
        $this->minkContext->assertPageContainsText('Token activated');
        $this->minkContext->assertPageContainsText('The user has proven posession of his token');
    }
}
