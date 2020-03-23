Feature: A RA manages tokens tokens registered in the selfservice portal
  In order to manage tokens
  As a RA
  I must be able to manage second factor tokens in RA

  Scenario: Provision an institution and a user to promote later on by an authorized institution
    Given institution "institution-a.example.com" can "use_ra" from institution "institution-a.example.com"
      And institution "institution-a.example.com" can "select_raa" from institution "institution-a.example.com"
      And institution "institution-d.example.com" can "use_ra" from institution "institution-a.example.com"
      And a user "Jane Toppan" identified by "urn:collab:person:institution-a.example.com:jane-a-ra" from institution "institution-a.example.com"
      And the user "urn:collab:person:institution-a.example.com:jane-a-ra" has a vetted "yubikey"
      And the user "urn:collab:person:institution-a.example.com:jane-a-ra" has the role "ra" for institution "institution-a.example.com"

  Scenario: RA user can vet a token from an institution it is RA for
    Given I am logged in into the selfservice portal as "joe-a1"
    And I register a new SMS token
    And I verify my e-mail address
    When I am logged in into the ra portal as "jane-a-ra" with a "yubikey" token
     And I vet the last added second factor

  Scenario: RA user can view the audit log of an institution identity
    Given I am logged in into the ra portal as "jane-a-ra" with a "yubikey" token
    When I visit the Tokens page
    And I open the audit log for a user of "institution-a.example.com"
    Then I should see "institution-a.example.com" in the audit log identity overview

  Scenario: RA user can remove the token of an identity
    Given I am logged in into the ra portal as "jane-a-ra" with a "yubikey" token
    When I visit the Tokens page
    And I remove token with identifier "+31 (0) 612345678" from user "joe-a1 institution-a.example.com"
