<?php

use Behat\Behat\Context\Context;
use Behat\Behat\Hook\Scope\BeforeScenarioScope;
use Behat\Gherkin\Node\TableNode;
use Behat\Mink\Element\NodeElement;
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
        // We visit the RA location url
        $this->minkContext->visit($this->raUrl);

        $this->iAmLoggedInIntoTheRaPortalAs('admin', 'yubikey');
        $this->iVetASecondFactor($this->selfServiceContext->getVerifiedSecondFactorId(), $this->selfServiceContext->getActivationCode());
    }


    /**
     * @Given /^I vet the last added second factor$/
     */
    public function iVetTheLastAddedSecondFactor()
    {
        $secondFactorId = $this->selfServiceContext->getVerifiedSecondFactorId();
        $activationCode = $this->selfServiceContext->getActivationCode();

        $this->findsTokenForActivation($activationCode);
        $this->userProvesPosessionOfSmsToken($secondFactorId);
        $this->adminVerifiesUserIdentity($secondFactorId);
        $this->vettingProcessIsCompleted($secondFactorId);
    }

    /**
     * @Given /^I vet a second factor with id "([^"]*)" and with activation code "([^"]*)"$/
     */
    public function iVetASecondFactor($secondFactorId, $activationCode)
    {
        // We visit the RA location url
        $this->minkContext->visit($this->raUrl);

        $this->findsTokenForActivation($activationCode);
        $this->userProvesPosessionOfSmsToken($secondFactorId);
        $this->adminVerifiesUserIdentity($secondFactorId);
        $this->vettingProcessIsCompleted($secondFactorId);
    }


    /**
     * @Given /^I am logged in into the ra portal as "([^"]*)" with a "([^"]*)" token$/
     */
    public function iAmLoggedInIntoTheRaPortalAs($userName, $tokenType)
    {
        // Login into RA
        $this->iTryToLoginIntoTheRaPortalAs($userName, $tokenType);

        // We are now on the RA homepage
        $this->minkContext->assertPageAddress('https://ra.stepup.example.com');
        $this->minkContext->assertPageContainsText('RA Management Portal');
        $this->minkContext->assertPageContainsText('Token activation');
    }

    /**
     * @Given /^I try to login into the ra portal as "([^"]*)" with a "([^"]*)" token$/
     */
    public function iTryToLoginIntoTheRaPortalAs($userName, $tokenType)
    {
        $this->minkContext->getSession()->stop();
        $this->minkContext->getSession()->setCookie('testcookie', 'testcookie');

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
    }


    /**
     * @Given /^I visit the "([^"]*)" page in the RA environment$/
     */
    public function iVisitAPageInTheRaEnvironment($uri)
    {
        // We visit the RA location url
        $this->minkContext->visit($this->raUrl.'/'.$uri);
    }

    public function findsTokenForActivation($activationCode)
    {
        // The activation token was previously set on the SP context, and can be retrieved here.
        $this->minkContext->fillField('ra_start_vetting_procedure_registrationCode', $activationCode);
        $this->minkContext->pressButton('Search');
    }

    /**
     * @When /^I search for "([^"]*)" on the token activation page$/
     */
    public function iSearchForOnTheTokenActivationPage($registrationCode)
    {
        // We visit the RA location url which is the search page
        $this->minkContext->visit($this->raUrl);
        $this->minkContext->fillField('ra_start_vetting_procedure_registrationCode', $registrationCode);
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

    private function userProvesPosessionOfSmsToken($secondFactorId)
    {
        $vettingProcedureUrl = 'https://ra.stepup.example.com/vetting-procedure/%s/send-sms-challenge';

        $this->minkContext->assertPageAddress(
            sprintf(
                $vettingProcedureUrl,
                $secondFactorId
            )
        );

        // Press the initiate vetting procedure button in the search results
        $this->minkContext->pressButton('Send code');
        // Fill the Code field with an arbitrary verification code
        $this->minkContext->fillField('ra_verify_phone_number_challenge', '999');
        $this->minkContext->pressButton('Verify code');
    }

    private function adminVerifiesUserIdentity($verifiedSecondFactorId)
    {
        $vettingProcedureUrl = 'https://ra.stepup.example.com/vetting-procedure/%s/verify-identity';

        $this->minkContext->assertPageAddress(
            sprintf(
                $vettingProcedureUrl,
                $verifiedSecondFactorId
            )
        );
        $this->minkContext->fillField('ra_verify_identity_documentNumber', '654321');
        $this->minkContext->checkOption('ra_verify_identity_identityVerified');
        $this->minkContext->pressButton('Verify identity');
    }

    private function vettingProcessIsCompleted($verifiedSecondFactorId)
    {
        $vettingProcedureUrl = 'https://ra.stepup.example.com/vetting-procedure/%s/completed';

        $this->minkContext->assertPageAddress(
            sprintf(
                $vettingProcedureUrl,
                $verifiedSecondFactorId
            )
        );
        $this->minkContext->assertPageContainsText('Token activated');
        $this->minkContext->assertPageContainsText('The user has proven posession of his token');
    }

    /**
     * @When /^I switch to institution "([^"]*)" with institution switcher$/
     */
    public function iSwitchWithRaaSwitcherToInstitutionWithName($institutionName)
    {
        $this->minkContext->selectOption('select_institution_institution', $institutionName);
        $this->minkContext->pressButton('select_institution_select_and_apply');
    }

    /**
     * @Given /^I visit the RA promotion page$/
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
     * @Given /^I visit the Tokens page$/
     */
    public function iVisitTheTokensPage()
    {
        $this->minkContext->clickLink('Tokens');
        $this->minkContext->assertPageAddress('https://ra.stepup.example.com/second-factors');
    }

    /**
     * @When I filter the :arg1 filter on :arg2
     */
    public function iFilterTheForm($filter, $filterValue)
    {
        $this->minkContext->assertPageAddress('https://ra.stepup.example.com/second-factors');
        $this->minkContext->selectOption($filter, $filterValue);
        $this->minkContext->pressButton('Search');
    }

    /**
     * @Then I should see :arg1 in the search results
     */
    public function searchResultsShouldInclude($expectation)
    {
        $this->minkContext->assertElementContainsText('.search-second-factors table', $expectation);
    }

    /**
     * @When I open the audit log for a user of :arg1
     */
    public function openFirstAuditLogForInstitution($institution)
    {
        $page = $this->minkContext->getSession()->getPage();
        $searchResult = $page->find('xpath', sprintf("//td[contains(.,'%s')]/..", $institution));
        if (is_null($searchResult) || !$searchResult->has('css', 'a.audit-log')) {
            throw new Exception(
                sprintf('No tokens found for institution "%s"', $institution)
            );
        }
        $searchResult->clickLink('Audit log');
    }

    /**
     * @When I click on the token export button
     */
    public function clickOnTheTokenExportButton()
    {
        $page = $this->minkContext->getSession()->getPage();
        $page->pressButton('Export');
    }

    /**
     * @Then I should not see a token export button
     */
    public function shouldNotSeeATokenExportButton()
    {
        $page = $this->minkContext->getSession()->getPage();
        if ($page->hasButton('Export') ) {
            throw new Exception(
                sprintf('A token export button should not be visible')
            );
        }
    }

    /**
     * @Then I should see :arg1 in the audit log identity overview
     */
    public function iShouldSeeInAuditLogIdentityOverview($institution)
    {
        $page = $this->minkContext->getSession()->getPage();
        $searchResult = $page->find('xpath', sprintf("//td[contains(.,'%s')]", $institution));

        if (is_null($searchResult)) {
            throw new Exception(
                sprintf('The institution "%s" was not found in the audit log identity overview.', $institution)
            );
        }
    }

    /**
     * @Given I remove token from user :arg1
     */
    public function removeTokenFromUser($name)
    {
        $this->removeTokenWithIdentifierFromUser('03945859', $name);
    }

    /**
     * @Then I remove token with identifier :arg2 from user :arg1
     */
    public function removeTokenWithIdentifierFromUser($identifier, $name)
    {
        $page = $this->minkContext->getSession()->getPage();

        // Get row
        /** @var NodeElement[] $searchResults */
        $searchResults = $page->findAll('xpath', sprintf("//td[contains(.,'%s')]/..", $name));
        if (empty($searchResults)) {
            throw new Exception(
                sprintf('No tokens found for user "%s"', $name)
            );
        }
        $token = null;
        foreach ($searchResults as $searchResult) {
            $button = $searchResult->find('css', sprintf('[data-sfidentifier=%s].btn.revoke', json_encode($identifier)));
            if ($button) {
                $token = $button;
            }
        }
        if (is_null($token)) {
            throw new Exception(
                sprintf('Token with identifier not found for user "%s"', $name)
            );
        }

        // Get button data
        $sfIdentifier = $token->getAttribute('data-sfid');
        $identityIdentifier = $token->getAttribute('data-sfidentityid');

        // Fill data in hidden revocation form
        $page->find('css', 'input[name="ra_revoke_second_factor[identityId]"]')->setValue($identityIdentifier);
        $page->find('css', 'input[name="ra_revoke_second_factor[secondFactorId]"]')->setValue($sfIdentifier);
        $form = $page->find('css', "form[name=ra_revoke_second_factor]");
        $form->submit();

        $this->minkContext->assertElementContainsText('#flash .alert', 'The token has been successfully removed');
    }


    /**
     * @Then I should not see :arg1 in the search results
     */
    public function searchResultsShouldNotInclude($expectation)
    {
        $this->minkContext->assertElementNotContainsText('.search-second-factors table', $expectation);
    }

    /**
     * @Then /^I change the role of "([^"]*)" to become "([^"]*)" for institution "([^"]*)"$/
     */
    public function iChangeTheRoleOfToBecome($userName, $role, $institution)
    {
        if (!in_array($role, ['RA', 'RAA']) ) {
            throw new Exception(
                sprintf('The role %s is invalid', $role)
            );
        }

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

        $searchResult->pressButton('Add role');

        $this->minkContext->assertPageContainsText('Contact Information');
        $this->minkContext->assertPageContainsText($userName);

        // Fill the form with arbitrary text
        $this->minkContext->fillField('ra_management_create_ra_location', 'Basement of institution-a');
        $this->minkContext->fillField('ra_management_create_ra_contactInformation', 'Desk B12, Institution A');
        $this->minkContext->selectOption('ra_management_create_ra_roleAtInstitution_role', $role);
        $this->minkContext->selectOption('ra_management_create_ra_roleAtInstitution_institution', $institution);

        // Promote the user by clicking the button
        $this->minkContext->pressButton('ra_management_create_ra_button-group_create_ra');

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
        $this->minkContext->assertPageContainsText('Add RA(A)');
    }

    /**
     * @Then /^I relieve "([^"]*)" from "([^"]*)" of his "([^"]*)" role$/
     */
    public function iRelieveOfHisRole($userName, $institution, $role)
    {
        $page = $this->minkContext->getSession()->getPage();

        // There should be a td with the username in it, select that TR to press that button on.
        $searchResult = $page->findAll('xpath', sprintf("//tr[./td[contains(.,'%s')]]", $userName));

        /** @var \Behat\Mink\Element\NodeElement $result */
        foreach ($searchResult as $result) {
            $raa = $result->find('css', 'td:nth-of-type(4)');

            if ($raa->getText() === $role.' @ '.$institution) {

                $result->pressButton('Remove role');
                $this->minkContext->assertPageContainsText('Are you sure you want to remove the user below as RA(A)?');
                $this->minkContext->pressButton('Confirm');
                $this->minkContext->assertPageContainsText('The Identity is no longer RA(A)');

                return;
            }
        }

        throw new Exception(
            sprintf('The ra(a) with username "%s" could not be found in the search results', $userName)
        );
    }

    /**
     * @Given /^I should see the following candidates:$/
     * @param TableNode $table
     */
    public function iShouldSeeTheFollowingCandidates(TableNode $table)
    {
        $this->iShouldSeeTheFollowingCandidateFors(null, $table);
    }

    /**
     * @Given /^I should see the following candidates for "([^"]*)":$/
     * @param TableNode $table
     */
    public function iShouldSeeTheFollowingCandidateFors($forInstitution, TableNode $table)
    {
        $page = $this->minkContext->getSession()->getPage();

        // build hashmap to check identities
        $data = [];
        $hash = $table->getHash();
        foreach ($hash as $row) {
            $key = $row['name'] . '|' . $row['institution'];
            $data[$key] = true;
        }

        // get identities form page
        $searchResult = $page->findAll('xpath', "//tr[./td]");
        foreach ($searchResult as $result) {

            $name = $result->find('css', 'td:nth-of-type(2)')->getText();
            $institution = $result->find('css', 'td:nth-of-type(1)')->getText();
            $key = $name . '|' . $institution;

            if (($forInstitution == $institution || is_null($forInstitution)) && !array_key_exists($key, $data)) {
                throw new Exception(sprintf('Unexpected user found on page: "%s"', $key));
            }

            unset($data[$key]);
        }

        // check if all are found
        if (!empty($data)) {
            throw new Exception(sprintf('User(s) not found on page: "%s"', json_encode(array_keys($data))));
        }
    }

    /**
     * @Given /^I should see the following raas:$/
     * @param TableNode $table
     */
    public function iShouldSeeTheFollowingRaas(TableNode $table)
    {
        $page = $this->minkContext->getSession()->getPage();

        // build hashmap to check identities
        $data = [];
        $hash = $table->getHash();
        foreach ($hash as $row) {
            $key = $row['name'] . '|' . $row['role'] .' @ '. $row['institution'];
            $data[$key] = true;
        }

        // get identities form page
        $searchResult = $page->findAll('xpath', "//tr[./td]");
        foreach ($searchResult as $result) {
            $name = $result->find('css', 'td:nth-of-type(1)')->getText();
            $role = $result->find('css', 'td:nth-of-type(4)')->getText();
            $key = $name . '|' . $role;

            if (!array_key_exists($key, $data)) {
                throw new Exception(sprintf('Unexpected user found on page: "%s"', $key));
            }

            unset($data[$key]);
        }

        // check if all are found
        if (!empty($data)) {
            throw new Exception(sprintf('User(s) not found on page: "%s"', json_encode(array_keys($data))));
        }
    }

    /**
     * @Given /^The institution configuration should be:$/
     */
    public function theInstitutionConfigurationShouldBe(TableNode $table)
    {
        $page = $this->minkContext->getSession()->getPage();

        $data = [];
        $hash = $table->getColumnsHash();
        foreach ($hash as $row) {
            $key = $row['Label'] . '|' . $row['Value'];
            $data[$key] = true;
        }

        // get identities form page
        $searchResult = $page->findAll('xpath', "//tr");
        foreach ($searchResult as $result) {
            $label = $result->find('css', 'th')->getText();
            $value = $result->find('css', 'td')->getText();
            $key = sprintf("%s|%s", $label, $value);

            if (!array_key_exists($key, $data)) {
                throw new Exception(sprintf('Unexpected configuration found: "%s"', $key));
            }
            unset($data[$key]);
        }

        // Check if all are found
        if (!empty($data)) {
            throw new Exception(sprintf('Configuration options that are not found on page: "%s"', json_encode(array_keys($data))));
        }
    }
    /**
     * @Given /^I should see the following profile:$/
     * @param TableNode $table
     */
    public function iShouldSeeTheFollowingProfile(TableNode $table)
    {
        $page = $this->minkContext->getSession()->getPage();

        // build hashmap to check identities
        $data = [];
        $hash = $table->getHash();
        foreach ($hash as $row) {
            $key = sprintf("%s|%s", $row['Label'], $row['Value']);
            $data[$key] = true;
        }

        // Load the table data from the page
        $searchResult = $page->findAll('xpath', "//tr");
        foreach ($searchResult as $result) {
            $label = $result->find('css', 'th')->getText();
            $value = $result->find('css', 'td')->getText();
            $key = sprintf("%s|%s", $label, $value);

            if (!array_key_exists($key, $data)) {
                throw new Exception(sprintf('Unexpected profile data found on page: "%s"', $key));
            }

            unset($data[$key]);
        }
        // check if all are found
        if (!empty($data)) {
            throw new Exception(sprintf('Missing profile data: "%s"', json_encode(array_keys($data))));
        }
    }
}
