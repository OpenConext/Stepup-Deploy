Feature: A management user reads and writes institution configuration in the middleware API
  In order to configure institutions
  As an application management user
  I must be able to read/write institution configuration to the middleware API

  Scenario: Management user reads the current institution configuration before updating the FGA settings
    Given I authenticate with user "management" and password "secret"
    And I set the "Content-Type" header to be "application/json"
    And I set the "Accept" header to be "application/json"
    When I request "GET /management/institution-configuration"
    Then the api response status code should be 200
    And institute "institution-a.example.com" has a property "use_ra" which equals null
    And institute "institution-a.example.com" has a property "use_raa" which equals null
    And institute "institution-a.example.com" has a property "select_raa" which equals null

  Scenario: Management user posts a new institution configuration for institution-a.example.com
    Given I have the payload
      """
      {
        "institution-a.example.com": {
          "use_ra_locations": true,
          "show_raa_contact_information": true,
          "verify_email": true,
          "allowed_second_factors": [],
          "number_of_tokens_per_identity": 2,
          "use_ra": ["institution-a.example.com", "institution-b.example.com"],
          "use_raa": ["institution-a.example.com"],
          "select_raa": []
        }
      }
      """
    And I authenticate with user "management" and password "secret"
    And I set the "Content-Type" header to be "application/json"
    And I set the "Accept" header to be "application/json"
    When I request "POST /management/institution-configuration"
    Then the api response status code should be 200
    And the "status" property should equal "OK"

  Scenario: Management user reads the updated institution configuration after updating the FGA settings
    Given I authenticate with user "management" and password "secret"
    And I set the "Content-Type" header to be "application/json"
    And I set the "Accept" header to be "application/json"
    When I request "GET /management/institution-configuration"
    Then the api response status code should be 200
    And institute "institution-a.example.com" has a property "use_ra" which equals "institution-a.example.com, institution-b.example.com"
    And institute "institution-a.example.com" has a property "use_raa" which equals "institution-a.example.com"
    And institute "institution-a.example.com" has a property "select_raa" which equals ""