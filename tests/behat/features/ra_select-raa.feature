Feature: A RAA manages tokens tokens registered in the selfservice portal
  In order to manage tokens
  As a RAA
  I must be able to manage second factor tokens from my institution

  Scenario: Provision a institution and a user to promote later on by an authorized institution
    Given a user "Joe Satriani" identified by "urn:collab:person:institution-d.example.com:joe-d1" from institution "institution-d.example.com"
    And the user "urn:collab:person:institution-d.example.com:joe-d1" has a vetted "yubikey"
    And institution "institution-a.example.com" can "select_raa" from institution "institution-a.example.com"
    And institution "institution-a.example.com" can "select_raa" from institution "institution-d.example.com"
    And institution "institution-d.example.com" can "select_raa" from institution "institution-a.example.com"

  Scenario: SRAA user promotes "jane-a1" to be an RAA
    Given I am logged in into the ra portal as "admin" with a "yubikey" token
    When I switch to institution "institution-a.example.com" with SRAA switcher
    And I visit the RA Management RA promotion page
    Then I change the role of "jane-a1 institution-a.example.com" to become "RAA" for institution "institution-d.example.com"

  Scenario: User "jane-a1" promotes "joe-d1" to be an RA
    Given I am logged in into the ra portal as "jane-a1" with a "yubikey" token
    And I visit the RA Management RA promotion page
    Then I change the role of "Joe Satriani" to become "RA" for institution "institution-d.example.com"

  Scenario: User "jane-a1" demotes "joe-d1" to no longer be an RA
    And I visit the RA Management page
    Then I relieve "Joe Satriani" of his RA role

  Scenario: SRAA user demotes "jane-a1" to no longer be an RAA
    Given I am logged in into the ra portal as "admin" with a "yubikey" token
    When I switch to institution "institution-a.example.com" with SRAA switcher
    And I visit the RA Management page
    Then I relieve "jane-a1 institution-a.example.com" of his RA role
