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
    And a user "Jane Toppan" identified by "urn:collab:person:institution-a.example.com:jane-a-raa" from institution "institution-a.example.com" with UUID "00000000-0000-4000-8000-000000000001"
    And the user "urn:collab:person:institution-a.example.com:jane-a-raa" has a vetted "yubikey"
    And the user "urn:collab:person:institution-a.example.com:jane-a-raa" has the role "raa" for institution "institution-a.example.com"

  Scenario: A user sees the locations of institutions it's RAA for
    Given I am logged in into the ra portal as "jane-a-raa" with a "yubikey" token
     When I visit the "locations" page in the RA environment
     Then I should see "Locations of institution-a.example.com"
        And I should see "No RA locations found for the current institution."
     Then I switch to institution "institution-d.example.com" with institution switcher
        And I should see "Locations of institution-d.example.com"
        And I should see "No RA locations found for the current institution."

  Scenario: A user can add locations of an institution it's RAA for
    Given I am logged in into the ra portal as "jane-a-raa" with a "yubikey" token
    When I visit the "locations" page in the RA environment
      And I switch to institution "institution-d.example.com" with institution switcher
      And I should see "Locations of institution-d.example.com"
      And I should see "No RA locations found for the current institution."
      And I follow "Add an RA Location"
      And I fill in the following:
        | ra_create_ra_location_name               | The name of the test location for institution D   |
        | ra_create_ra_location_location           | The location itself for institution D             |
        | ra_create_ra_location_contactInformation | An address for the test location of institution D |
      And I press "ra_create_ra_location_create_ra_location"
    Then I should see "Locations of institution-d.example.com"
      And I should see "The name of the test location for institution D"
      And I should see "The location itself for institution D"
      And I should see "An address for the test location of institution D"
    Then I switch to institution "institution-a.example.com" with institution switcher
      And I should see "Locations of institution-a.example.com"
      And I should see "No RA locations found for the current institution."

  Scenario: A user can edit the added location of an institution it's RAA for
    Given I am logged in into the ra portal as "jane-a-raa" with a "yubikey" token
    When I visit the "locations" page in the RA environment
      And I switch to institution "institution-d.example.com" with institution switcher
      And I should see "Locations of institution-d.example.com"
      And I should see "The name of the test location for institution D"
      And I follow "Edit"
      And I fill in the following:
        | ra_change_ra_location_name               | The name of the test location for institution D, updated!   |
        | ra_change_ra_location_location           | The location itself for institution D, updated!             |
        | ra_change_ra_location_contactInformation | An address for the test location of institution D, updated! |
      And I press "ra_change_ra_location_change_ra_location"
    Then I should see "Locations of institution-d.example.com"
      And I should see "The name of the test location for institution D, updated!"
      And I should see "The location itself for institution D, updated!"
      And I should see "An address for the test location of institution D, updated!"
    Then I switch to institution "institution-a.example.com" with institution switcher
      And I should see "Locations of institution-a.example.com"
      And I should see "No RA locations found for the current institution."

  # TODO: test delete endpoint and confirmation modal