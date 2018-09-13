Feature: A RAA manages tokens tokens registered in the selfservice portal
  In order to manage tokens
  As a RAA
  I must be able to manage second factor tokens from my institution

  Scenario: SRAA user promotes "jane-a1" to be an RA
    Given I am logged in into the ra portal as "admin" with a "yubikey" token
     When I switch to institution "institution-a.example.com"
      And I visit the RA Management RA promotion page
     Then I change the role of "jane-a1" to become RA

  Scenario: SRAA user demotes "jane-a1" to no longer be an RA
    Given I am logged in into the ra portal as "admin" with a "yubikey" token
     When I switch to institution "institution-a.example.com"
      And I visit the RA Management page
     Then I relieve "jane-a1" of his RA role
