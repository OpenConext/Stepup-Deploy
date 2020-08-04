Feature: A RA vets tokens tokens registered in the selfservice portal
  In order to manage tokens
  As a RA
  I must be able to manage second factor tokens in RA

  Scenario: Provision an institution and a user
    Given institution "institution-a.example.com" can "use_ra" from institution "institution-a.example.com"
      And institution "institution-a.example.com" can "select_raa" from institution "institution-a.example.com"
      And a user "Janis Bower" identified by "urn:collab:person:institution-a.example.com:janis-a-ra" from institution "institution-a.example.com"
      And the user "urn:collab:person:institution-a.example.com:janis-a-ra" has a vetted "yubikey"
      And the user "urn:collab:person:institution-a.example.com:janis-a-ra" has the role "ra" for institution "institution-a.example.com"

  Scenario: Demo GSSP does not require proof of possession
    Given I am logged in into the selfservice portal as "joe-a1"
    And I register a new demogssp2 token
    And I verify my e-mail address
    When I am logged in into the ra portal as "jane-a-ra" with a "yubikey" token
    Then I vet the last added second factor, not requiring proof of possession
