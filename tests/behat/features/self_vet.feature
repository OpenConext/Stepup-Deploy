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

  Scenario: A user registers a token in selfservice
    Given I am logged in into the selfservice portal as "joe-a1"
    When I register a new SMS token
    And I verify my e-mail address
    And I vet my second factor at the information desk
    And I self-vet a new demo token with my SMS token
    Then I visit the "overview" page in the selfservice portal
    Then I should see "The following tokens are registered for your account."
    And I should see "SMS"
    And I should see "Dummy"
