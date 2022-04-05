Feature: Use case B: Institutions sharing vetting locations
  Allow users from institutions that cannot easily visit the vetting location at the institution, e.g. because
  they work remotely or abroad, to use the RA services of another institution that is closer to their location. By
  pooling the RAs from different geographical locations, the access for users to RA services is improved.

  Scenario: Scenario: Setup of the institution configuration and test users
     Given I have the payload
        """
        {
            "institution-a.example.com": {
                "use_ra_locations": true,
                "show_raa_contact_information": true,
                "verify_email": true,
                "self_vet": false,
                "allowed_second_factors": [],
                "number_of_tokens_per_identity": 1,
                "use_ra": [
                    "institution-a.example.com",
                    "institution-d.example.com"
                ]
            },
            "institution-d.example.com": {
                "use_ra_locations": true,
                "show_raa_contact_information": true,
                "verify_email": true,
                "self_vet": false,
                "allowed_second_factors": [],
                "number_of_tokens_per_identity": 1,
                "use_ra": [
                    "institution-a.example.com",
                    "institution-d.example.com"
                ]
            }
        }
        """
      And I authenticate to the Middleware API
      And I request "POST /management/institution-configuration"
      And a user "RA institution A" identified by "urn:collab:person:institution-a.example.com:joe-a-ra" from institution "institution-a.example.com"
      And the user "urn:collab:person:institution-a.example.com:joe-a-ra" has a vetted "yubikey" with identifier "00000004"
      And the user "urn:collab:person:institution-a.example.com:joe-a-ra" has the role "ra" for institution "institution-a.example.com"
      And a user "RA institution D" identified by "urn:collab:person:institution-d.example.com:joe-d-ra" from institution "institution-d.example.com"
      And the user "urn:collab:person:institution-d.example.com:joe-d-ra" has a vetted "yubikey" with identifier "00000005"
      And the user "urn:collab:person:institution-d.example.com:joe-d-ra" has the role "ra" for institution "institution-d.example.com"
      And a user "Jane Jackson" identified by "urn:collab:person:institution-a.example.com:jane-a1" from institution "institution-a.example.com"
      And the user "urn:collab:person:institution-a.example.com:jane-a1" has a verified "yubikey" with registration code "1234ABCD"
      And a user "Joe Satriani" identified by "urn:collab:person:institution-d.example.com:joe-d1" from institution "institution-d.example.com"
      And the user "urn:collab:person:institution-d.example.com:joe-d1" has a verified "yubikey" with registration code "ABCD1234"

  Scenario: The institution A RA can vet identities from institution A and D
      And I am logged in into the ra portal as "joe-a-ra" with a "yubikey" token
     When I search for "ABCD1234" on the token activation page
     Then I should see "Please connect the user's personal Yubikey with your computer"
     When I search for "1234ABCD" on the token activation page
     Then I should see "Please connect the user's personal Yubikey with your computer"

  Scenario: The institution D RA can vet identities from institution A and D
    Given I am logged in into the ra portal as "joe-d-ra" with a "yubikey" token
     When I search for "ABCD1234" on the token activation page
     Then I should see "Please connect the user's personal Yubikey with your computer"
     When I search for "1234ABCD" on the token activation page
     Then I should see "Please connect the user's personal Yubikey with your computer"
