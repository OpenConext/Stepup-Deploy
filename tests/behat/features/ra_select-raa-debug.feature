Feature: A RAA manages tokens tokens registered in the selfservice portal
  In order to manage tokens
  As a RAA
  I must be able to promote and demote identities to RA(A)'s

  Scenario: Provision a institution and a user to promote later on by an authorized institution
    Given a user "joe-a-raa" identified by "urn:collab:person:institution-a.example.com:joe-a-raa" from institution "institution-a.example.com"
    And the user "urn:collab:person:institution-a.example.com:joe-a-raa" has a vetted "yubikey" with identifier "00000004"
    Given a user "jane-d-user" identified by "urn:collab:person:institution-d.example.com:jane-d-user" from institution "institution-d.example.com"
    And the user "urn:collab:person:institution-d.example.com:jane-d-user" has a vetted "yubikey" with identifier "00000005"

    And institution "institution-a.example.com" can "use_ra" from institution "institution-a.example.com"
    And institution "institution-a.example.com" can "use_raa" from institution "institution-a.example.com"
    And institution "institution-a.example.com" can "select_raa" from institution "institution-a.example.com"
    And institution "institution-a.example.com" can "select_raa" from institution "institution-d.example.com"

    And institution "institution-d.example.com" can "use_ra" from institution "institution-d.example.com"
    And institution "institution-d.example.com" can "use_raa" from institution "institution-d.example.com"
    And institution "institution-d.example.com" can "select_raa" from institution "institution-d.example.com"
    And institution "institution-d.example.com" can "select_raa" from institution "institution-a.example.com"

  Scenario: SRAA user promotes "joe-a-raa" to be an RAA
    Given I am logged in into the ra portal as "admin" with a "yubikey" token
    And I visit the RA promotion page
    Then I change the role of "joe-a-raa" to become "RAA" for institution "institution-a.example.com"

  Scenario: User "joe-a-raa" promotes "jane-d-user" to be an RAA
    Given I am logged in into the ra portal as "joe-a-raa" with a "yubikey" token
    And I visit the RA promotion page
    Then I change the role of "jane-d-user" to become "RAA" for institution "institution-d.example.com"
