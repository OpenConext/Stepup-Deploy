Feature: Identities are capable of 'vetting' their own tokens
  In order to register a self asserted token (SAT)
  As an identity
  I must be able to use the self-service environment to register a recovery token and self-vet a SF token

  Scenario: Setup of the institution configuration and test users
    Given I have the payload
        """
        {
            "stepup.example.com": {
                "use_ra_locations": true,
                "show_raa_contact_information": true,
                "verify_email": false,
                "self_vet": false,
                "allow_self_asserted_tokens": false,
                "allowed_second_factors": [],
                "number_of_tokens_per_identity": 2
            },
            "institution-a.example.com": {
                "use_ra_locations": true,
                "show_raa_contact_information": true,
                "verify_email": false,
                "self_vet": true,
                "allow_self_asserted_tokens": true,
                "allowed_second_factors": [],
                "number_of_tokens_per_identity": 2
            }
        }
        """
    And I authenticate to the Middleware API
    And I request "POST /management/institution-configuration"

  Scenario: Identity can enter the SAT registration flow
    Given I am logged in into the selfservice portal as "joe-a1"
    And start registration of a self-asserted "SMS" token
    And create a "safe-store" recovery token
    Then I should see a LoA "1.5" "SMS" token
    And I should see a "safe-store" recovery token

  Scenario: A yubikey also yields a 1.5 token
    Given I am logged in into the selfservice portal as "joe-a2"
    And start registration of a self-asserted "Yubikey" token
    And create a "safe-store" recovery token
    Then I should see a LoA "1.5" "Yubikey" token

  Scenario: Joe Atwo can self-vet a second token using his SAT token
    Given I am logged in into the selfservice portal as "joe-a2"
    And I self-vet a new SMS token with my Yubikey token
    Then I should see a LoA "1.5" "Yubikey" token
    And  I should see a LoA "1.5" "SMS" token

  Scenario: Joe Athree loses his token but is capable of recovering it via the safe store recovery token
    Given I am logged in into the selfservice portal as "joe-a3"
    And start registration of a self-asserted "SMS" token
    And create a "safe-store" recovery token
    And I revoke my "SMS" token
    And I register a "SMS" token using the "safe-store" recovery token
    Then I should see a LoA "1.5" "SMS" token
    And I should see a "safe-store" recovery token

  Scenario: Joe Afour loses his token but is capable of recovering it via the SMS recovery token
    Given I am logged in into the selfservice portal as "joe-a4"
    And start registration of a self-asserted "Yubikey" token
    And create a "SMS" recovery token
    And I revoke my "Yubikey" token
    And I register a "Yubikey" token using the "SMS" recovery token
    Then I should see a LoA "1.5" "Yubikey" token
    And I should see a "SMS" recovery token

 Scenario: Joe Afour creates a second recovery token
   Given I am logged in into the selfservice portal as "joe-a4"
    And I register a "safe-store" recovery token
    Then I should see a "SMS" recovery token
    And I should see a "safe-store" recovery token


