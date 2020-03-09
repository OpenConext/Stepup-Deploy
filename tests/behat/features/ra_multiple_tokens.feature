Feature: A RAA manages tokens tokens registered in the selfservice portal
  In order to manage tokens
  As a RAA
  I must be able to manage second factor tokens from my institution

  Scenario: Provision a institution and a user to promote later on by an authorized institution
    Given institution "institution-a.example.com" can "select_raa" from institution "institution-a.example.com"
    And institution "institution-b.example.com" can "select_raa" from institution "institution-a.example.com"
    And institution "institution-d.example.com" can "select_raa" from institution "institution-a.example.com"
    And a user "Jane Toppan" identified by "urn:collab:person:institution-a.example.com:jane-a-ra" from institution "institution-a.example.com"
    And the user "urn:collab:person:institution-a.example.com:jane-a-ra" has a vetted "yubikey" with identifier "00000004"
    And the user "urn:collab:person:institution-a.example.com:jane-a-ra" has a vetted "u2f" with identifier "00000005"
    And the user "urn:collab:person:institution-a.example.com:jane-a-ra" has the role "raa" for institution "institution-a.example.com"
    And the user "urn:collab:person:institution-a.example.com:jane-a-ra" has the role "raa" for institution "institution-b.example.com"
    And the user "urn:collab:person:institution-a.example.com:jane-a-ra" has the role "raa" for institution "institution-d.example.com"

  Scenario: SRAA user checks if "Jane Toppan" is not a candidate for institutions
    Given I am logged in into the ra portal as "admin" with a "yubikey" token
    When I visit the RA promotion page
    Then I should see the following candidates:
      | name                              | institution               |
      | jane-a1 institution-a.example.com | institution-a.example.com |
      | Admin                             | stepup.example.com        |

  Scenario: SRAA user checks if "Jane Toppan" is a candidate for institutions if relieved from the RAA role
    Given I am logged in into the ra portal as "admin" with a "yubikey" token
    When I visit the RA Management page
     And I relieve "Jane Toppan" from "institution-a.example.com" of his "RAA" role
    Then I visit the RA promotion page
    And I should see the following candidates:
      | name                              | institution               |
      | jane-a1 institution-a.example.com | institution-a.example.com |
      | Admin                             | stepup.example.com        |
      | Jane Toppan                       | institution-a.example.com |

  Scenario: Sraa revokes only one vetted token from "Jane Toppan" and that shouldn't remove her as candidate
    Given I am logged in into the ra portal as "admin" with a "yubikey" token
    When I visit the Tokens page
      And I remove token with identifier "00000004" from user "Jane Toppan"
    Then I visit the RA promotion page
      And I should see the following candidates:
        | name                              | institution               |
        | jane-a1 institution-a.example.com | institution-a.example.com |
        | Admin                             | stepup.example.com        |
        | Jane Toppan                       | institution-a.example.com |

  Scenario: Sraa revokes the last vetted token from "Jane Toppan" and that must remove her as candidate
    Given I am logged in into the ra portal as "admin" with a "yubikey" token
    When I visit the Tokens page
      And I remove token with identifier "00000005" from user "Jane Toppan"
    Then I visit the RA promotion page
      And I should see the following candidates:
        | name                              | institution               |
        | jane-a1 institution-a.example.com | institution-a.example.com |
        | Admin                             | stepup.example.com        |