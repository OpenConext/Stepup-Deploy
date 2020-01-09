Feature: A RA(A) should only have access to certain pages

  Scenario: Provision an institution and a user to promote later on by an authorized institution
    Given institution "stepup.example.com" can "select_raa" from institution "stepup.example.com"
    And institution "institution-a.example.com" can "use_ra" from institution "stepup.example.com"
    And institution "institution-b.example.com" can "use_raa" from institution "stepup.example.com"
    And institution "institution-d.example.com" can "select_raa" from institution "institution-d.example.com"
    And institution "institution-d.example.com" can "use_raa" from institution "institution-d.example.com"
    And a user "RA institution A" identified by "urn:collab:person:stepup.example.com:joe--ra" from institution "stepup.example.com" with UUID "00000000-0000-4000-a000-000000000001"
    And a user "RAA institution B" identified by "urn:collab:person:stepup.example.com:joe--raa" from institution "stepup.example.com" with UUID "00000000-0000-4000-a000-000000000002"
    And a user "RAA institution D" identified by "urn:collab:person:institution-d.example.com:joe-d-raa" from institution "institution-d.example.com" with UUID "00000000-0000-4000-a000-000000000003"
    And a user "RA(A) candidate" identified by "urn:collab:person:institution-d.example.com:joe--candidate" from institution "stepup.example.com" with UUID "00000000-0000-4000-a000-000000000004"
    And the user "urn:collab:person:stepup.example.com:joe--ra" has a vetted "yubikey"
    And the user "urn:collab:person:stepup.example.com:joe--raa" has a vetted "yubikey"
    And the user "urn:collab:person:institution-d.example.com:joe-d-raa" has a vetted "yubikey"
    And the user "urn:collab:person:institution-d.example.com:joe--candidate" has a vetted "yubikey"
    And the user "urn:collab:person:stepup.example.com:joe--ra" has the role "ra" for institution "stepup.example.com"
    And the user "urn:collab:person:stepup.example.com:joe--raa" has the role "raa" for institution "stepup.example.com"
    And the user "urn:collab:person:institution-d.example.com:joe-d-raa" has the role "raa" for institution "institution-d.example.com"


  # Token page
  Scenario: An anonymous user can not view the tokens page
    Given I visit the "second-factors" page in the RA environment
    Then I should see "Enter your username and password"

  Scenario: RA can view the tokens page
    Given I am logged in into the ra portal as "joe--ra" with a "yubikey" token
    When I visit the "second-factors" page in the RA environment
    Then the response status code should be 200

  Scenario: RAA can view the tokens page
    Given I am logged in into the ra portal as "joe--raa" with a "yubikey" token
    When I visit the "second-factors" page in the RA environment
    Then the response status code should be 200

  Scenario: RAA from other institution can view the tokens page
    Given I am logged in into the ra portal as "joe-d-raa" with a "yubikey" token
    When I visit the "second-factors" page in the RA environment
    Then the response status code should be 200

  Scenario: SRAA can view the tokens page
    Given I am logged in into the ra portal as "admin" with a "yubikey" token
    When I visit the "second-factors" page in the RA environment
    Then the response status code should be 200


  # RA-management page
  Scenario: An anonymous user can not view the ra-management page
    Given I visit the "management/ra" page in the RA environment
    Then I should see "Enter your username and password"

  Scenario: RA can not view the ra-management page
    Given I am logged in into the ra portal as "joe--ra" with a "yubikey" token
    When I visit the "management/ra" page in the RA environment
    Then the response status code should be 403

  Scenario: RAA can view the ra-management page
    Given I am logged in into the ra portal as "joe--raa" with a "yubikey" token
    When I visit the "management/ra" page in the RA environment
    Then the response status code should be 200

  Scenario: RAA from another institution can not view the ra-management page
    Given I am logged in into the ra portal as "joe-d-raa" with a "yubikey" token
    When I visit the "management/ra" page in the RA environment
    Then the response status code should be 200

  Scenario: SRAA can view the ra-management page
    Given I am logged in into the ra portal as "admin" with a "yubikey" token
    When I visit the "management/ra" page in the RA environment
    Then the response status code should be 200


  # RA-management create page
  Scenario: An anonymous user can not view the ra-management create page
    Given I visit the "management/create-ra/00000000-0000-4000-a000-000000000004" page in the RA environment
    Then I should see "Enter your username and password"

  Scenario: RA can not view the ra-management create page
    Given I am logged in into the ra portal as "joe--ra" with a "yubikey" token
    When I visit the "management/create-ra/00000000-0000-4000-a000-000000000004" page in the RA environment
    Then the response status code should be 403

  Scenario: RAA can view the ra-management create page
    Given I am logged in into the ra portal as "joe--raa" with a "yubikey" token
    When I visit the "management/create-ra/00000000-0000-4000-a000-000000000004" page in the RA environment
    Then the response status code should be 200

  Scenario: RAA from another institution can not view the ra-management create page
    Given I am logged in into the ra portal as "joe-d-raa" with a "yubikey" token
    When I visit the "management/create-ra/00000000-0000-4000-a000-000000000004" page in the RA environment
    Then the response status code should be 404

  Scenario: SRAA can view the ra-management create page
    Given I am logged in into the ra portal as "admin" with a "yubikey" token
    When I visit the "management/create-ra/00000000-0000-4000-a000-000000000004" page in the RA environment
    Then the response status code should be 200


  # RA-management amend page
  Scenario: An anonymous user can not view the ra-management amend page
    Given I visit the "management/amend-ra-information/00000000-0000-4000-a000-000000000001/stepup.example.com" page in the RA environment
    Then I should see "Enter your username and password"

  Scenario: RA can not view the ra-management amend page
    Given I am logged in into the ra portal as "joe--ra" with a "yubikey" token
    When I visit the "management/amend-ra-information/00000000-0000-4000-a000-000000000001/stepup.example.com" page in the RA environment
    Then the response status code should be 403

  Scenario: RAA can view the ra-management amend page
    Given I am logged in into the ra portal as "joe--raa" with a "yubikey" token
    When I visit the "management/amend-ra-information/00000000-0000-4000-a000-000000000001/stepup.example.com" page in the RA environment
    Then the response status code should be 200

  Scenario: RAA from institution-c can not view the ra-management amend page
    Given I am logged in into the ra portal as "joe-d-raa" with a "yubikey" token
    When I visit the "management/amend-ra-information/00000000-0000-4000-a000-000000000001/stepup.example.com" page in the RA environment
    Then the response status code should be 404

  Scenario: SRAA can view the ra-management amend page
    Given I am logged in into the ra portal as "admin" with a "yubikey" token
    When I visit the "management/amend-ra-information/00000000-0000-4000-a000-000000000001/stepup.example.com" page in the RA environment
    Then the response status code should be 200


  # RA-management retract page
  Scenario: An anonymous user can not view the ra-management retract page
    Given I visit the "management/retract-registration-authority/00000000-0000-4000-a000-000000000001/stepup.example.com" page in the RA environment
    Then I should see "Enter your username and password"

  Scenario: RA can not view the ra-management retract page
    Given I am logged in into the ra portal as "joe--ra" with a "yubikey" token
    When I visit the "management/retract-registration-authority/00000000-0000-4000-a000-000000000001/stepup.example.com" page in the RA environment
    Then the response status code should be 403

  Scenario: RAA can view the ra-management retract page
    Given I am logged in into the ra portal as "joe--raa" with a "yubikey" token
    When I visit the "management/retract-registration-authority/00000000-0000-4000-a000-000000000001/stepup.example.com" page in the RA environment
    Then the response status code should be 200

  Scenario: RAA from another institution can not view the ra-management retract page
    Given I am logged in into the ra portal as "joe-d-raa" with a "yubikey" token
    When I visit the "management/retract-registration-authority/00000000-0000-4000-a000-000000000001/stepup.example.com" page in the RA environment
    Then the response status code should be 404

  Scenario: SRAA can view the ra-management retract page
    Given I am logged in into the ra portal as "admin" with a "yubikey" token
    When I visit the "management/retract-registration-authority/00000000-0000-4000-a000-000000000001/stepup.example.com" page in the RA environment
    Then the response status code should be 200


  # RA-candidate page
  Scenario: An anonymous user can not view the ra-candidate page
    Given I visit the "management/search-ra-candidate" page in the RA environment
    Then I should see "Enter your username and password"

  Scenario: RA can not view the ra-candidate page
    Given I am logged in into the ra portal as "joe--ra" with a "yubikey" token
    When I visit the "management/search-ra-candidate" page in the RA environment
    Then the response status code should be 403

  Scenario: RAA can view the ra-candidate page
    Given I am logged in into the ra portal as "joe--raa" with a "yubikey" token
    When I visit the "management/search-ra-candidate" page in the RA environment
    Then the response status code should be 200

  Scenario: RAA from another institution can view the ra-candidate page
    Given I am logged in into the ra portal as "joe--raa" with a "yubikey" token
    When I visit the "management/search-ra-candidate" page in the RA environment
    Then the response status code should be 200

  Scenario: SRAA can view the ra-candidate page
    Given I am logged in into the ra portal as "admin" with a "yubikey" token
    When I visit the "management/search-ra-candidate" page in the RA environment
    Then the response status code should be 200