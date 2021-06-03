Feature: The application managers are concerned with correct data ending up in the event stream
  In order to ensure no sensitive data ends up in the event stream
  As an administrator
  I must check the payload of the events for presence of sensitive data

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
   Then the resulting "SecondFactorVetted" event should not contain "common_name"
   And the resulting "SecondFactorVetted" event should not contain "vetting_type"
   And the resulting "SecondFactorVetted" event should not contain "document_number"
   And the resulting "SecondFactorVetted" event should contain "name_id"