Feature: A RAA can view the institution configuration

  Scenario: Jane Toppan is RAA at Institution A
    Given I have the payload
        """
        {
            "institution-a.example.com": {
                "use_ra_locations": true,
                "show_raa_contact_information": true,
                "verify_email": true,
                "allowed_second_factors": [],
                "number_of_tokens_per_identity": 2
            },
            "institution-d.example.com": {
                "use_ra_locations": false,
                "show_raa_contact_information": false,
                "verify_email": false,
                "allowed_second_factors": ["sms"],
                "number_of_tokens_per_identity": 1,
                "use_raa": [
                    "institution-a.example.com"
                ]
            }
        }
        """
    And I authenticate to the Middleware API
    And I request "POST /management/institution-configuration"
    And a user "Jane Toppan" identified by "urn:collab:person:institution-a.example.com:jane-a-raa" from institution "institution-a.example.com" with UUID "00000000-0000-0000-0000-000000000001"
    And the user "urn:collab:person:institution-a.example.com:jane-a-raa" has a vetted "yubikey"
    And the user "urn:collab:person:institution-a.example.com:jane-a-raa" has the role "raa" for institution "institution-a.example.com"

  Scenario: RAA user for institution A sees the institution-configuration for that institution
    Given I am logged in into the ra portal as "jane-a-raa" with a "yubikey" token
     When I visit the "locations" page in the RA environment
     Then I should see "Locations of institution-a.example.com"
        And I should see "No RA locations found for the current institution."
     Then I switch to institution "institution-d.example.com" with institution switcher
        And I should see "Locations of institution-d.example.com"
        And I should see "No RA locations found for the current institution."