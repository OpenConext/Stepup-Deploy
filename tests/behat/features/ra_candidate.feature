Feature: A RAA manages ra candidates in the ra environment
  In order to promote candidates
  As a RAA
  I must be able to promote and demote identities

  Scenario: Provision a institution and a user to promote later on by an authorized institution
    Given institution "institution-a.example.com" can "select_raa" from institution "institution-a.example.com"
    And institution "institution-b.example.com" can "select_raa" from institution "institution-a.example.com"
    And institution "institution-d.example.com" can "select_raa" from institution "institution-a.example.com"
    And a user "Jane Toppan" identified by "urn:collab:person:institution-a.example.com:jane-a-ra" from institution "institution-a.example.com"
    # The two users below are only used to create institutions for the SRAA switcher
    And a user "DUMMY1" identified by "urn:collab:person:institution-b.example.com:dummy1" from institution "institution-b.example.com"
    And a user "DUMMY2" identified by "urn:collab:person:institution-d.example.com:dummy2" from institution "institution-d.example.com"
    And the user "urn:collab:person:institution-a.example.com:jane-a-ra" has a vetted "yubikey"
    And the user "urn:collab:person:institution-a.example.com:jane-a-ra" has the role "raa" for institution "institution-a.example.com"
    And the user "urn:collab:person:institution-a.example.com:jane-a-ra" has the role "raa" for institution "institution-b.example.com"
    And the user "urn:collab:person:institution-a.example.com:jane-a-ra" has the role "raa" for institution "institution-d.example.com"

  Scenario: SRAA user checks if "Jane Toppan" is a candidate for all institutions (without filtering)
    Given I am logged in into the ra portal as "admin" with a "yubikey" token
    When I visit the RA promotion page
    Then I should see the following candidates:
      | name                              | institution               |
      | jane-a1 institution-a.example.com | institution-a.example.com |
      | Admin                             | stepup.example.com        |

  Scenario: SRAA user checks if "Jane Toppan" is a candidate for all institutions (with filtering on institution-a)
    Given I am logged in into the ra portal as "admin" with a "yubikey" token
    When I visit the RA promotion page
    Then I should see the following candidates for "institution-a.example.com":
      | name                              | institution               |
      | jane-a1 institution-a.example.com | institution-a.example.com |

  Scenario: SRAA user checks if "Jane Toppan" is a candidate for all institutions (with filtering on institution-b)
    Given I am logged in into the ra portal as "admin" with a "yubikey" token
    When I visit the RA promotion page
    Then I should see the following candidates for "institution-b.example.com":
      | name                              | institution               |
      | jane-a1 institution-a.example.com | institution-a.example.com |

  Scenario: SRAA user demotes "Jane" to no longer be an RAA for "institution-a"
    Given I am logged in into the ra portal as "admin" with a "yubikey" token
    When I visit the RA Management page
    Then I relieve "Jane Toppan" from "institution-a.example.com" of his "RAA" role

  Scenario: SRAA user checks if "Jane Toppan" is a candidate for "institution-a"
    Given I am logged in into the ra portal as "admin" with a "yubikey" token
    When I visit the RA promotion page
    Then I should see the following candidates for "institution-a.example.com":
      | name                              | institution               |
      | jane-a1 institution-a.example.com | institution-a.example.com |
      | Jane Toppan                       | institution-a.example.com |

  Scenario: SRAA user checks if "Jane Toppan" is not a candidate for "institution-b"
    Given I am logged in into the ra portal as "admin" with a "yubikey" token
    When I visit the RA promotion page
    Then I should see the following candidates for "institution-b.example.com":
      | name                              | institution               |
      | jane-a1 institution-a.example.com | institution-a.example.com |

  Scenario: SRAA user checks if "Jane Toppan" is not listed for "institution-a"
    Given I am logged in into the ra portal as "admin" with a "yubikey" token
    When I visit the RA Management page
    Then I should see the following raas:
      | name        | institution               | role |
      | Jane Toppan | institution-b.example.com | RAA  |
      | Jane Toppan | institution-d.example.com | RAA  |

  Scenario: SRAA user checks if "Jane Toppan" is listed for "institution-b"
    Given I am logged in into the ra portal as "admin" with a "yubikey" token
    When I visit the RA Management page
    Then I should see the following raas:
      | name        | institution               | role |
      | Jane Toppan | institution-b.example.com | RAA  |
      | Jane Toppan | institution-d.example.com | RAA  |