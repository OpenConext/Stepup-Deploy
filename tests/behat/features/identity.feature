Feature: A (S)RA(A) user reads identities of StepUp users in the middleware API
  In order to list identities
  As a (S)RA(A) user
  I must be able to read from the middleware API

  Scenario: A (S)RA(A) user reads identities without additional authorization context
    Given I authenticate with user "ra" and password "secret"
    When I request "GET /identity?institution=institution-a.example.com"
    Then the api response status code should be 200
    And the "items" property should contain 2 items

  Scenario: A (S)RA(A) user reads identities of a non existent institution
    Given I authenticate with user "ra" and password "secret"
    When I request "GET /identity?institution=institution-x.example.com"
    Then the api response status code should be 200
    And the "items" property should be an empty array

  Scenario: The admin SRAA user reads identities with authorization context
    Given I authenticate with user "ra" and password "secret"
    When I request "GET /identity?institution=institution-a.example.com&actorId=dc4cc738-5f1c-4d8c-84a2-d6faf8aded89&actorInstitution=stepup.example.com"
    Then the api response status code should be 200
    And the "items" property should contain 2 items

  Scenario: The admin SRAA user reads identities with authorization context of a non existent institution
    Given I authenticate with user "ra" and password "secret"
    When I request "GET /identity?institution=institution-x.example.com&actorId=dc4cc738-5f1c-4d8c-84a2-d6faf8aded89&actorInstitution=stepup.example.com"
    Then the api response status code should be 200
    And the "items" property should be an empty array