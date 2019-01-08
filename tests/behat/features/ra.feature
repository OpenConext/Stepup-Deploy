Feature: A RAA manages tokens tokens registered in the selfservice portal
  In order to manage tokens
  As a RAA
  I must be able to manage second factor tokens from my institution

  Scenario: RA user can't vet a token from another institution it is not RA for
    Given a user "Jane Toppan" identified by "urn:collab:person:institution-a.example.com:jane-a-ra" from institution "institution-a.example.com"
      And institution "institution-a.example.com" can "use_ra" from institution "institution-a.example.com"
      And institution "institution-a.example.com" can "use_ra" from institution "institution-d.example.com"
      And institution "institution-a.example.com" can "select_raa" from institution "institution-a.example.com"
      And the user "urn:collab:person:institution-a.example.com:jane-a-ra" has a vetted "yubikey"
      And the user "urn:collab:person:institution-a.example.com:jane-a-ra" has the role "ra" for institution "institution-a.example.com"
      And a user "Joe Satriani" identified by "urn:collab:person:institution-d.example.com:joe-d1" from institution "institution-d.example.com"
      And the user "urn:collab:person:institution-d.example.com:joe-d1" has a verified "yubikey" with registration code "1234ABCD"
      And a user "Joe Perry" identified by "urn:collab:person:institution-e.example.com:joe-e1" from institution "institution-e.example.com"
      And the user "urn:collab:person:institution-e.example.com:joe-e1" has a verified "yubikey" with registration code "9876WXYZ"
      And I am logged in into the ra portal as "jane-a-ra" with a "yubikey" token
     When I search for "9876WXYZ" on the token activation page
     Then I should see "Unknown activation code"

  Scenario: RA user can view the audit log of another institution identity
    Given I am logged in into the ra portal as "jane-a-ra" with a "yubikey" token
    When I visit the Tokens page
    And I open the audit log for a user of "institution-d.example.com"
    Then I should see "institution-d.example.com" in the audit log identity overview

  Scenario: RA user can view token overview and sees tokens from other institutions
    Given I am logged in into the ra portal as "jane-a-ra" with a "yubikey" token
     When I visit the Tokens page
     Then I should see "institution-a.example.com" in the search results
      And I should see "institution-d.example.com" in the search results

  Scenario: RA user can filter the token overview
    Given I am logged in into the ra portal as "jane-a-ra" with a "yubikey" token
     When I visit the Tokens page
      And I filter the "Institution" filter on "institution-d.example.com"
      And I should see "institution-d.example.com" in the search results
     Then I should not see "institution-a.example.com" in the search results

  Scenario: RA user can vet a token from another institution it is RA for
    Given I am logged in into the ra portal as "jane-a-ra" with a "yubikey" token
     When I search for "1234ABCD" on the token activation page
     Then I should see "Please connect the user's personal Yubikey with your computer"

  Scenario: SRAA user promotes "jane-a1" to be an RA
    Given I am logged in into the ra portal as "admin" with a "yubikey" token
     When I switch to institution "institution-a.example.com" with SRAA switcher
      And I visit the RA Management RA promotion page
     Then I change the role of "jane-a1 institution-a.example.com" to become "RA" for institution "institution-a.example.com"

  Scenario: SRAA user demotes "jane-a1" to no longer be an RA
    Given I am logged in into the ra portal as "admin" with a "yubikey" token
     When I switch to institution "institution-a.example.com" with SRAA switcher
      And I visit the RA Management page
     Then I relieve "jane-a1 institution-a.example.com" of his RA role
