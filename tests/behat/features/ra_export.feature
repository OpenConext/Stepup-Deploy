Feature: A RAA can export tokens registered in the selfservice portal
  In order to export tokens
  As a RAA
  I must be able to export second factor tokens

  Scenario: RA user can't vet a token from another institution it is not RA for
    Given a user "Jane Ra" identified by "urn:collab:person:institution-a.example.com:jane-a-ra" from institution "institution-a.example.com"
      And a user "Jane Raa" identified by "urn:collab:person:institution-a.example.com:jane-a-raa" from institution "institution-a.example.com"
      And a user "Joe Raa and Ra" identified by "urn:collab:person:institution-a.example.com:joe-a-raa" from institution "institution-a.example.com"
      And institution "institution-a.example.com" can "use_ra" from institution "institution-a.example.com"
      And institution "institution-a.example.com" can "use_raa" from institution "institution-a.example.com"
      And institution "institution-a.example.com" can "select_raa" from institution "institution-a.example.com"
      And institution "institution-b.example.com" can "use_raa" from institution "institution-b.example.com"
      And institution "institution-b.example.com" can "select_raa" from institution "institution-a.example.com"
      And the user "urn:collab:person:institution-a.example.com:jane-a-ra" has a vetted "yubikey"
      And the user "urn:collab:person:institution-a.example.com:jane-a-ra" has the role "ra" for institution "institution-a.example.com"
      And the user "urn:collab:person:institution-a.example.com:jane-a-raa" has a vetted "yubikey"
      And the user "urn:collab:person:institution-a.example.com:jane-a-raa" has the role "raa" for institution "institution-a.example.com"
      And the user "urn:collab:person:institution-a.example.com:joe-a-raa" has a vetted "yubikey"
      And the user "urn:collab:person:institution-a.example.com:joe-a-raa" has the role "ra" for institution "institution-a.example.com"
      And the user "urn:collab:person:institution-a.example.com:joe-a-raa" has the role "raa" for institution "institution-b.example.com"

  Scenario: an RA user can not export tokens
    Given I am logged in into the ra portal as "jane-a-ra" with a "yubikey" token
    When I visit the Tokens page
    Then I should not see a token export button

  Scenario: an RAA user can export tokens
    Given I am logged in into the ra portal as "jane-a-raa" with a "yubikey" token
    When I visit the Tokens page
      And I click on the token export button
    Then the response should contain "Token ID,Type,Name,Email,Institution,Document Number,Status"
      And the response should contain "03945859,yubikey,Jane Raa,foo@bar.com,institution-a.example.com,123456,vetted"
      And the response should contain "03945859,yubikey,Jane Ra,foo@bar.com,institution-a.example.com,123456,vetted"

  Scenario: a user which is at least RAA for one institution can export tokens
    Given I am logged in into the ra portal as "joe-a-raa" with a "yubikey" token
    When I visit the Tokens page
      And I click on the token export button
    Then the response should contain "Token ID,Type,Name,Email,Institution,Document Number,Status"
      And the response should contain "03945859,yubikey,Jane Raa,foo@bar.com,institution-a.example.com,123456,vetted"
      And the response should contain "03945859,yubikey,Jane Ra,foo@bar.com,institution-a.example.com,123456,vetted"
