<?php

use Behat\Behat\Context\Context;
use Behat\Behat\Hook\Scope\BeforeScenarioScope;
use Behat\MinkExtension\Context\MinkContext;

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
        $this->minkContext->getMink()->setDefaultSessionName(FeatureContext::SESSION_RA);

        // We visit the RA location url
        $this->minkContext->visit($this->raUrl);

        $this->iAmLoggedInIntoTheRaPortalAs('admin', 'yubikey');
        $this->findsTokenForActivation();
        $this->userProvesPosessionOfSmsToken();
        $this->adminVerifiesUserIdentity();
        $this->vettingProcessIsCompleted();

        // Switch back to the default session
        $this->minkContext->getMink()->setDefaultSessionName(FeatureContext::SESSION_DEFAULT);
    }

    /**
     * @Given /^I am logged in into the ra portal as "([^"]*)" with a "([^"]*)" token$/
     */
    public function iAmLoggedInIntoTheRaPortalAs($userName, $tokenType)
    {
        // The ra session is used to vet the token
        $this->minkContext->getMink()->setDefaultSessionName(FeatureContext::SESSION_RA);

        // We visit the RA location url
        $this->minkContext->visit($this->raUrl);

        // The admin user logs in and gives a Yubikey second factor
        $this->authContext->authenticateWithIdentityProviderFor($userName);

        switch ($tokenType) {
            case "yubikey":
                $this->authContext->verifyYuikeySecondFactor();
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

    private function userProvesPosessionOfSmsToken()
    {
        $vettingProcedureUrl = 'https://ra.stepup.example.com/vetting-procedure/%s/send-sms-challenge';

        $this->minkContext->assertPageAddress(
            sprintf(
                $vettingProcedureUrl,
                $this->selfServiceContext->getVerifiedSecondFactorId()
            )
        );

        // Press the initiate vetting procedure button in the search results
        $this->minkContext->pressButton('Send code');
        // Fill the Code field with an arbitrary verification code
        $this->minkContext->fillField('ra_verify_phone_number_challenge', '999');
        $this->minkContext->pressButton('Verify code');
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

    /**
     * @When /^I switch to institution "([^"]*)"$/
     */
    public function iSwitchToInstitutionWithName($institutionName)
    {
        $this->minkContext->clickLink('stepup.example.com');
        $this->minkContext->assertPageAddress('https://ra.stepup.example.com/sraa/select-institution');
        $this->minkContext->selectOption('sraa_institution_select_institution', $institutionName);
        $this->minkContext->pressButton('sraa_institution_select_select_and_apply');
        $this->minkContext->assertPageContainsText('Your institution has been changed to "institution-a.example.com" ');
    }

    /**
     * @Given /^I visit the RA Management RA promotion page$/
     */
    public function iVisitTheRAManagementRAPromotionPage()
    {
        $this->minkContext->assertElementOnPage('[href="/management/ra"]');
        $this->minkContext->clickLink('RA Management');
        $this->minkContext->assertElementOnPage('[href="/management/search-ra-candidate"]');
        $this->minkContext->clickLink('Add RA(A)');
        $this->minkContext->assertPageAddress('https://ra.stepup.example.com/management/search-ra-candidate');
    }

    /**
     * @Then /^I change the role of "([^"]*)" to become RA$/
     */
    public function iChangeTheRoleOfToBecomeRA($userName)
    {
        $this->minkContext->assertPageAddress('https://ra.stepup.example.com/management/search-ra-candidate');
        $this->minkContext->fillField('ra_search_ra_candidates_name', $userName);
        $this->minkContext->pressButton('ra_search_ra_candidates_search');

        $page = $this->minkContext->getSession()->getPage();
        // There should be a td with the username in it, select that TR to press that button on.
        $searchResult = $page->find('xpath', sprintf("//td[contains(.,'%s')]/..", $userName));

        if (is_null($searchResult) || !$searchResult->has('css', 'a.btn-info[role="button"]')) {
            throw new Exception(
                sprintf('The user with username "%s" could not be found in the search results', $userName)
            );
        }

        $searchResult->pressButton('Change role');

        $this->minkContext->assertPageContainsText('Contact Information');
        $this->minkContext->assertPageContainsText($userName);

        // Fill the form with arbitrary text
        $this->minkContext->fillField('ra_management_create_ra_location', 'Basement of institution-a');
        $this->minkContext->fillField('ra_management_create_ra_contactInformation', 'Desk B12, Institution A');
        $this->minkContext->selectOption('ra_management_create_ra_role', 'RA');

        // Promote the user by clicking the button
        $this->minkContext->pressButton('ra_management_create_ra_create_ra');

        // If your Session supports Javascript, then enable these two lines. The configured sessions use Goutte, which
        // is based on Guzzle and is not able to evaluate Javascript.

        // $this->minkContext->assertPageContainsText('Are you sure you want to give the user below the selected role?');
        // $this->minkContext->pressButton('Confirm');

        $this->minkContext->assertPageAddress('https://ra.stepup.example.com/management/search-ra-candidate');
        $this->minkContext->assertPageContainsText('The role of this user has been changed.');
    }

    /**
     * @Given /^I visit the RA Management page$/
     */
    public function iVisitTheRAManagementPage()
    {
        $this->minkContext->assertElementOnPage('[href="/management/ra"]');
        $this->minkContext->clickLink('RA Management');
        $this->minkContext->assertPageContainsText('Remove role');
    }

    /**
     * @Then /^I relieve "([^"]*)" of his RA role$/
     */
    public function iRelieveOfHisRole($userName)
    {
        $page = $this->minkContext->getSession()->getPage();
        // There should be a td with the username in it, select that TR to press that button on.
        $searchResult = $page->find('xpath', sprintf("//td[contains(.,'%s')]/..", $userName));

        if (is_null($searchResult) || !$searchResult->has('css', 'a.btn-info[role="button"]')) {
            throw new Exception(
                sprintf('The user with username "%s" could not be found in the search results', $userName)
            );
        }
        $searchResult->pressButton('Remove role');
        $this->minkContext->assertPageContainsText('Are you sure you want to remove the user below as RA(A)?');
        $this->minkContext->pressButton('Confirm');
        $this->minkContext->assertPageContainsText('The Identity is no longer RA(A)');
    }
}
