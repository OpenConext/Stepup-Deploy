Feature: A user manages his tokens in the selfservice portal
  In order to use a self vetted second factor token
  As a user
  I must be able to manage my second factor tokens

  Scenario: Setup of the institution configuration and test users
    Given I have the payload
        """
        {
            "stepup.example.com": {
                "use_ra_locations": true,
                "show_raa_contact_information": true,
                "verify_email": true,
                "self_vet": false,
                "allowed_second_factors": [],
                "number_of_tokens_per_identity": 3
            },
            "institution-a.example.com": {
                "use_ra_locations": true,
                "show_raa_contact_information": true,
                "verify_email": true,
                "self_vet": true,
                "allowed_second_factors": [],
                "number_of_tokens_per_identity": 3
            }
        }
        """
    And I authenticate to the Middleware API
    And I request "POST /management/institution-configuration"

  Scenario: A user self vets a token in selfservice
    Given a user "Ponder Stibbons" identified by "urn:collab:person:institution-a.example.com:joe-a2" from institution "institution-a.example.com"
    And the user "urn:collab:person:institution-a.example.com:joe-a2" has a vetted "yubikey" identified by "01010101"
    And I am logged in into the selfservice portal as "joe-a2"
    And I self-vet a new SMS token with my Yubikey token
    And I visit the "overview" page in the selfservice portal
    Then I should see "The following tokens are registered for your account."
    And I should see "SMS"
    And I should see "Yubikey"

  Scenario: A user needs a suitable token to self vet
    Given a user "Ponder Stibbons" identified by "urn:collab:person:institution-a.example.com:joe-a2" from institution "institution-a.example.com"
    And the user "urn:collab:person:institution-a.example.com:joe-a2" has a vetted "sms" identified by "01010101"
    And I am logged in into the selfservice portal as "joe-a2"
    And I try to self-vet a new Yubikey token with my SMS token
    # The self vet option is not available on the token vetting page
    Then I should not see "Use your existing token"
