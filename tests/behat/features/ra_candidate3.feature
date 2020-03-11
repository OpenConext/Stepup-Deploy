Feature: A RAA manages ra candidates from virtual institutions in the ra environment
  In order to promote candidates from virtual institutions
  As a RAA
  I must be able to promote and demote identities were I'm allowed to through the authorization config

  Scenario: Provision an institution and a user to promote and demote later on by an authorized institution
    Given institution "institution-a.example.com" can "select_raa" from institution "institution-a.example.com"
      And institution "institution-a.example.com" can "use_ra" from institution "institution-a.example.com"
      And institution "institution-a.example.com" can "use_raa" from institution "institution-a.example.com"

      And institution "institution-d.example.com" can "select_raa" from institution "institution-a.example.com"

    And a user "joe-a-raa institution-a" identified by "urn:collab:person:institution-a.example.com:joe-a-raa" from institution "institution-a.example.com" with UUID "00000000-0000-4000-8000-000000000010"
      And the user "urn:collab:person:institution-a.example.com:joe-a-raa" has a vetted "yubikey"

  Scenario: RAA from institution a should see "joe-a-raa" as an RA(A) candidate from "institution-d"
    Given I am logged in into the ra portal as "admin" with a "yubikey" token
      And I visit the "management/create-ra/00000000-0000-4000-8000-000000000010" page in the RA environment
    Then the "#ra_management_create_ra_roleAtInstitution_institution" element should contain "institution-a.example.com"
      And the "#ra_management_create_ra_roleAtInstitution_institution" element should contain "institution-d.example.com"

  Scenario: SRAA user promotes "joe-a-raa" to be a RA for "institution-d"
    Given I am logged in into the ra portal as "admin" with a "yubikey" token
    And I visit the RA promotion page
    Then I change the role of "joe-a-raa institution-a" to become "RA" for institution "institution-d.example.com"

  Scenario: SRAA should not see "joe-a-raa" from "institution-d" as a RA(A) candidate for "institution-d"
    Given I am logged in into the ra portal as "admin" with a "yubikey" token
    And I visit the "management/create-ra/00000000-0000-4000-8000-000000000010" page in the RA environment
    Then the "#ra_management_create_ra_roleAtInstitution_institution" element should contain "institution-a.example.com"
    And the "#ra_management_create_ra_roleAtInstitution_institution" element should not contain "institution-d.example.com"

  Scenario: SRAA user demotes "joe-a-raa" from a RA of "institution-d"
    Given I am logged in into the ra portal as "admin" with a "yubikey" token
    And I visit the RA Management page
    Then I relieve "joe-a-raa institution-a" from "institution-d.example.com" of his "RA" role

  Scenario: RAA from institution a should see "joe-a-raa" again as an RA(A) candidate from "institution-d"
    Given I am logged in into the ra portal as "admin" with a "yubikey" token
      And I visit the "management/create-ra/00000000-0000-4000-8000-000000000010" page in the RA environment
    Then the "#ra_management_create_ra_roleAtInstitution_institution" element should contain "institution-a.example.com"
      And the "#ra_management_create_ra_roleAtInstitution_institution" element should contain "institution-d.example.com"