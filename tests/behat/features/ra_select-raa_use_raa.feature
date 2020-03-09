Feature: A RAA can only manage R RA(A)'s on the promotion page
  In order to manage RA(A)'s
  As a RAA
  I must only be able to manage RA(A)'s if select_raa is set but also use_raa is explicitly set

  Scenario: Provision an institution and a user to promote later on by an authorized institution
    Given a user "joe-a-raa" identified by "urn:collab:person:institution-a.example.com:joe-a-raa" from institution "institution-a.example.com" with UUID "00000000-0000-4000-a000-000000000001"
    And the user "urn:collab:person:institution-a.example.com:joe-a-raa" has a vetted "yubikey" with identifier "00000004"
    Given a user "jane-d-user" identified by "urn:collab:person:institution-d.example.com:jane-d-user" from institution "institution-d.example.com" with UUID "00000000-0000-4000-a000-000000000002"
    And the user "urn:collab:person:institution-d.example.com:jane-d-user" has a vetted "yubikey" with identifier "00000005"

    And institution "institution-a.example.com" can "use_raa" from institution "institution-a.example.com"
    And institution "institution-a.example.com" can "use_raa" from institution "institution-d.example.com"
    And institution "institution-a.example.com" can "select_raa" from institution "institution-a.example.com"
    And institution "institution-a.example.com" can "select_raa" from institution "institution-d.example.com"

    And institution "institution-d.example.com" can "use_raa" from institution "institution-a.example.com"
    And institution "institution-d.example.com" can "use_raa" from institution "institution-d.example.com"
#    And institution "institution-d.example.com" can "select_raa" from institution "institution-d.example.com"
    And institution "institution-d.example.com" can "select_raa" from institution "institution-a.example.com"

  Scenario: SRAA user promotes "joe-a-raa" to be an RAA
    Given I am logged in into the ra portal as "admin" with a "yubikey" token
    And I visit the RA promotion page
    Then I change the role of "joe-a-raa" to become "RAA" for institution "institution-a.example.com"

  Scenario: User "joe-a-raa" can only make "jane-d-user" to be an RAA for institution-a
    Given I am logged in into the ra portal as "joe-a-raa" with a "yubikey" token
    And I visit the "management/create-ra/00000000-0000-4000-a000-000000000002" page in the RA environment
    Then the "#ra_management_create_ra_roleAtInstitution_institution" element should not contain "institution-d.example.com"

