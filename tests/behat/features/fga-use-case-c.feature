Feature: Use case C: Closely cooperating institutions
  Two or more Institutions that are working (closely) together and that want to share their vetting
  infrastructure Note: the difference with the previous use case (B) is that in this use-case (C) each institution has
  fine grained control over who of the other institution may work for them.

  Note that in use-case B an institution allows all RAs from the other institution(s), it has no control over who these
  are, this is decided by the RAAs for the other institution. In this usecase each institution manages all its RAA(s),
  i.e. it chooses which persons from the other institution are RA. These users are not required to be an RA at the other
  institution.

  Scenario: Setup of the institution configuration and test users
     Given I have the payload
        """
        {
            "institution-a.example.com": {
                "use_ra_locations": true,
                "show_raa_contact_information": true,
                "verify_email": true,
                "allowed_second_factors": [],
                "number_of_tokens_per_identity": 1,
                "select_raa": [
                    "institution-a.example.com",
                    "institution-d.example.com"
                ],
                "use_raa": [
                    "institution-a.example.com"
                ]
            },
            "institution-d.example.com": {
                "use_ra_locations": true,
                "show_raa_contact_information": true,
                "verify_email": true,
                "allowed_second_factors": [],
                "number_of_tokens_per_identity": 1,
                "select_raa": [
                    "institution-a.example.com",
                    "institution-d.example.com"
                ],
                "use_raa": [
                    "institution-d.example.com"
                ]
            }
        }
        """
      And I authenticate to the Middleware API
      And I request "POST /management/institution-configuration"
      And a user "RAA institution A" identified by "urn:collab:person:institution-a.example.com:joe-a-raa" from institution "institution-a.example.com"
      And the user "urn:collab:person:institution-a.example.com:joe-a-raa" has a vetted "yubikey"
      And the user "urn:collab:person:institution-a.example.com:joe-a-raa" has the role "raa" for institution "institution-a.example.com"
      And a user "RAA institution D" identified by "urn:collab:person:institution-d.example.com:joe-d-raa" from institution "institution-d.example.com"
      And the user "urn:collab:person:institution-d.example.com:joe-d-raa" has a vetted "yubikey"
      And the user "urn:collab:person:institution-d.example.com:joe-d-raa" has the role "raa" for institution "institution-d.example.com"
      And a user "Jane Jackson" identified by "urn:collab:person:institution-a.example.com:jane-a1" from institution "institution-a.example.com"
      And the user "urn:collab:person:institution-a.example.com:jane-a1" has a vetted "yubikey"
      And a user "Joe Satriani" identified by "urn:collab:person:institution-d.example.com:joe-d1" from institution "institution-d.example.com"
      And the user "urn:collab:person:institution-d.example.com:joe-d1" has a vetted "yubikey"

  Scenario: The institution A RAA can promote identities from institution D
    Given I am logged in into the ra portal as "joe-a-raa" with a "yubikey" token
     When I visit the RA promotion page
     Then I change the role of "Joe Satriani" to become "RA" for institution "institution-a.example.com"

  Scenario: The institution D RAA can promote identities from institution A
    Given I am logged in into the ra portal as "joe-d-raa" with a "yubikey" token
     When I visit the RA promotion page
     Then I change the role of "Jane Jackson" to become "RA" for institution "institution-d.example.com"
