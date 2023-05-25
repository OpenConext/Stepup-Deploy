<?php

use Behat\Behat\Context\Context;
use Behat\Behat\Hook\Scope\BeforeScenarioScope;
use Behat\MinkExtension\Context\MinkContext;
use Behat\Behat\Hook\Scope\BeforeFeatureScope;
use Ramsey\Uuid\Uuid;
use Surfnet\StepupBehat\Factory\CommandPayloadFactory;
use Surfnet\StepupBehat\Repository\SecondFactorRepository;
use Surfnet\StepupBehat\ValueObject\ActivationContext;
use Surfnet\StepupBehat\ValueObject\Identity;
use Surfnet\StepupBehat\ValueObject\SecondFactorToken;
use Surfnet\StepupBehat\ValueObject\InstitutionConfiguration;

class FeatureContext implements Context
{
    /**
     * @var \Behat\MinkExtension\Context\MinkContext
     */
    private $minkContext;

    /**
     * @var ApiFeatureContext
     */
    private $apiContext;

    /**
     * @var SelfServiceContext
     */
    private $serlfServiceContext;

    /**
     * @var CommandPayloadFactory
     */
    private $payloadFactory;

    /**
     * @var SecondFactorRepository
     */
    private $repository;

    /**
     * @var InstitutionConfiguration
     */
    private $institutionConfiguration;

    /**
     * @BeforeFeature
     */
    public static function setupDatabase(BeforeFeatureScope $scope)
    {
        // Generate test databases
        echo "Preparing test schemas\n";
        shell_exec("php72 /src/Stepup-Middleware/bin/console doctrine:schema:drop --env=smoketest --force");
        shell_exec("php72 /src/Stepup-Gateway/bin/console doctrine:schema:drop --env=smoketest --force");
        shell_exec("php72 /src/Stepup-Middleware/bin/console doctrine:schema:create --env=smoketest");
        shell_exec("php72 /src/Stepup-Gateway/bin/console doctrine:schema:create --env=smoketest");

        echo "Replaying event stream\n";
        // Import the events.sql into middleware
        shell_exec("mysql -uroot -ppassword middleware_test < ./fixtures/events.sql");
        shell_exec("sh ./fixtures/mw-config-push.sh");
        // Perform an event replay
        shell_exec("php72 /src/Stepup-Middleware/bin/console middleware:event:replay --env=smoketest_event_replay --no-interaction -q");

        echo "Update the keys\n";
        // Update the `saml_entities` projection in `gateway_test`
        shell_exec("/deploy/tests/behat/fixtures/bin/override_sp_public_keys");
    }

    /**
     * @BeforeScenario
     */
    public function gatherContexts(BeforeScenarioScope $scope)
    {
        $environment = $scope->getEnvironment();

        $this->minkContext = $environment->getContext(MinkContext::class);
        $this->apiContext = $environment->getContext(ApiFeatureContext::class);
        $this->serlfServiceContext = $environment->getContext(SelfServiceContext::class);

        // Set the testcookie for both sessions, effectively putting the Stepup suite in test mode
        $this->minkContext->getSession()->setCookie('testcookie', 'testcookie');
        $this->minkContext->getSession('second')->setCookie('testcookie', 'testcookie');

        $this->payloadFactory = new CommandPayloadFactory();
        $this->repository = new SecondFactorRepository();
        $this->institutionConfiguration = new InstitutionConfiguration();
    }

    /**
     * @var Identity[]
     */
    private $identityStore = [];

    /**
     * @Given /^a user "([^"]*)" identified by "([^"]*)" from institution "([^"]*)"$/
     */
    public function aUserIdentifiedByWithAVettedTokenAndTheRole($commonName, $nameId, $institution)
    {
        $uuid = (string)Uuid::uuid4();

        return $this->aUserIdentifiedByWithAVettedTokenAndTheRoleWithUuid($commonName, $nameId, $institution, $uuid);
    }

    /**
     * @Given /^a user "([^"]*)" identified by "([^"]*)" from institution "([^"]*)" and fail with "([^"]*)"$/
     */
    public function anExceptionMessageIsExcpected($commonName, $nameId, $institution, $errorMessage)
    {
        try {
            $uuid = (string)Uuid::uuid4();
            return $this->aUserIdentifiedByWithAVettedTokenAndTheRoleWithUuid($commonName, $nameId, $institution, $uuid);
        } catch (Exception $e) {
            assertContains($errorMessage, $e->getMessage());
        }
    }

    /**
     * @Given /^a user "([^"]*)" identified by "([^"]*)" from institution "([^"]*)" with UUID "([^"]*)"$/
     */
    public function aUserIdentifiedByWithAVettedTokenAndTheRoleWithUuid($commonName, $nameId, $institution, $uuid)
    {
        $userId = (string)$uuid;

        $identity = Identity::from($userId, $nameId, $commonName, $institution, []);
        $this->identityStore[$nameId] = $identity;

        $this->setPayload($this->payloadFactory->build('Identity:CreateIdentity', $identity));
        $this->connectToApi('ss', 'secret');
        $this->apiContext->iRequest('POST', '/command');
    }

    /**
     * @Given /^institution "([^"]*)" can "([^"]*)" from institution "([^"]*)"$/
     */
    public function theInstitutionIsAuthorizedForAnotherInstitution($institution, $role, $raInstitution)
    {
        $this->institutionConfiguration->addRole($institution, $role, $raInstitution);
        $payload = $this->institutionConfiguration->getPayload();

        $this->setPayload($payload);
        $this->connectToApi('management', 'secret');
        $this->apiContext->iRequest('POST', '/management/institution-configuration');
    }

    private function connectToApi($username, $password)
    {
        $this->apiContext->iAuthenticateWithEmailAndPassword($username, $password);
    }

    private function setPayload($payload)
    {
        $this->apiContext->setPayload($payload);
    }

    /**
     * @Given /^the user "([^"]*)" has a vetted "([^"]*)" identified by "([^"]*)"$/
     */
    public function theUserHasAVetted($nameId, $tokenType, $identifier)
    {
        $this->theUserHasAVettedWithIdentifier($nameId, $tokenType, $identifier);
    }

    /**
     * @Given /^the user "([^"]*)" has a vetted "([^"]*)" with identifier "([^"]*)"$/
     */
    public function theUserHasAVettedWithIdentifier($nameId, $tokenType, $identifier)
    {
        // First test if this identity was already provisioned
        if (!isset($this->identityStore[$nameId])) {
            throw new InvalidArgumentException(
                sprintf(
                    'This identity "%s" is not yet known use the "aUserIdentifiedByWithAVettedTokenAndTheRole" step to create a new identity.',
                    $nameId
                )
            );
        }

        $tokenId = (string)Uuid::uuid4();
        $token = SecondFactorToken::from($tokenId, $tokenType, $identifier);
        $identityData = $this->identityStore[$nameId];
        $identityData->tokens = [$token];
        switch ($tokenType) {
            case "yubikey":
                // 1: Prove possession of the token
                $this->proveYubikeyPossession($identityData);
                break;
            case "sms":
                // 1: Prove possession of the token
                $this->proveSmsPosession($identityData);
                break;
            default:
                throw new InvalidArgumentException("This token type is not yet supported");
                break;
        }
        // 2: Mail verification
        $this->mailVerification($tokenId, $identityData);

        switch ($tokenType) {
            case "yubikey":
                // 3 Vet the yubikey
                $this->vetYubikeyToken($identityData);
                break;
            case "sms":
                // 3 Vet the yubikey
                $this->vetSmsToken($identityData);
                break;
            default:
                throw new InvalidArgumentException("This token type is not yet supported");
                break;
        }

    }

    /**
     * @Given /^the user "([^"]*)" has a verified "([^"]*)" with registration code "([^"]*)"$/
     */
    public function theUserHasAVerified($nameId, $tokenType, $registrationCode)
    {
        // First test if this identity was already provisioned
        if (!isset($this->identityStore[$nameId])) {
            throw new InvalidArgumentException(
                sprintf(
                    'This identity "%s" is not yet known use the "aUserIdentifiedByWithAVettedTokenAndTheRole" step to create a new identity.',
                    $nameId
                )
            );
        }

        $tokenId = (string)Uuid::uuid4();
        $this->theUserHasAVerifiedToken($nameId, $tokenType, $registrationCode, $tokenId);
    }


    /**
     * @Given /^the user "([^"]*)" has a verified "([^"]*)" with registration code "([^"]*)" and secondFactorId "([^"]*)"$/
     */
    public function theUserHasAVerifiedToken($nameId, $tokenType, $registrationCode, $tokenId)
    {
        // First test if this identity was already provisioned
        if (!isset($this->identityStore[$nameId])) {
            throw new InvalidArgumentException(
                sprintf(
                    'This identity "%s" is not yet known use the "aUserIdentifiedByWithAVettedTokenAndTheRole" step to create a new identity.',
                    $nameId
                )
            );
        }

        $token = SecondFactorToken::from($tokenId, $tokenType, '03945859');
        $identityData = $this->identityStore[$nameId];
        $identityData->tokens = [$token];

        // 1: Prove possession of the token
        $this->proveYubikeyPossession($identityData);

        // 2: Mail verification
        $this->mailVerification($tokenId, $identityData);

        // 3. Update the registration code (in the projection..)
        $this->repository->updateRegistrationCode($identityData->identityId, $registrationCode);
    }

    /**
     * @Given /^the user "([^"]*)" has the role "([^"]*)" for institution "([^"]*)"$/
     */
    public function theUserHasTheRole($nameId, $role, $institution)
    {
        // First test if this identity was already provisioned
        if (!isset($this->identityStore[$nameId])) {
            throw new InvalidArgumentException(
                sprintf(
                    'This identity "%s" is not yet known use the "aUserIdentifiedByWithAVettedTokenAndTheRole" step to create a new identity.',
                    $nameId
                )
            );
        }

        $actorId = 'dc4cc738-5f1c-4d8c-84a2-d6faf8aded89';
        $identityData = $this->identityStore[$nameId];
        $payload = $this->payloadFactory->buildRolePayload($actorId, $identityData->identityId, $identityData->institution, $role, $institution);
        $this->setPayload($payload);
        $this->connectToApi('ra', 'secret');
        $this->apiContext->iRequest('POST', '/command');
    }

    private function proveYubikeyPossession($identityData)
    {
        // 1.1 prove possession of a yubikey token
        $payload = $this->payloadFactory->build('Identity:ProveYubikeyPossession', $identityData);
        $this->setPayload($payload);
        $this->connectToApi('ss', 'secret');
        $this->apiContext->iRequest('POST', '/command');
    }

    private function proveSmsPosession($identityData)
    {
        // 1.1 prove possession of a yubikey token
        $payload = $this->payloadFactory->build('Identity:ProvePhonePossession', $identityData);
        $this->setPayload($payload);
        $this->connectToApi('ss', 'secret');
        $this->apiContext->iRequest('POST', '/command');
    }

    private function mailVerification($tokenId, $identityData)
    {
        // 2.1: Mail verification -> get verification nonce
        $nonce = $this->repository->findNonceById($tokenId);
        $identityData->tokens[0]->nonce = $nonce;

        // 2.2 Verify email was received
        $payload = $this->payloadFactory->build("Identity:VerifyEmail", $identityData);
        $this->setPayload($payload);
        $this->connectToApi('ss', 'secret');
        $this->apiContext->iRequest('POST', '/command');
    }

    private function vetYubikeyToken($identityData)
    {
        // 3.1. Retrieve the registration code
        $activationContext = new ActivationContext();
        $activationContext->registrationCode = $this->repository->getRegistrationCodeByIdentity($identityData->identityId);
        $activationContext->actorId = 'dc4cc738-5f1c-4d8c-84a2-d6faf8aded89';

        // 3.2  Vet the second factor device
        $identityData->activationContext = $activationContext;
        $payload = $this->payloadFactory->build('Identity:VetSecondFactor', $identityData);
        $this->setPayload($payload);
        $this->connectToApi('ra', 'secret');
        $this->apiContext->iRequest('POST', '/command');
    }

    private function vetSmsToken($identityData)
    {
        // 3.1. Retrieve the registration code
        $activationContext = new ActivationContext();
        $activationContext->registrationCode = $this->repository->getRegistrationCodeByIdentity($identityData->identityId);
        $activationContext->actorId = 'dc4cc738-5f1c-4d8c-84a2-d6faf8aded89';

        // 3.2  Vet the second factor device
        $identityData->activationContext = $activationContext;
        $payload = $this->payloadFactory->build('Identity:VetSecondFactor', $identityData);

        $this->setPayload($payload);
        $this->connectToApi('ra', 'secret');
        $this->apiContext->iRequest('POST', '/command');
    }
}
