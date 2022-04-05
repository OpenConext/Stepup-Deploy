Feature: Use case A: Institutions with few (10-20) users using a third party vetting service
  For institutions with few users that are using Stepup, for which setting up and maintaining a local vetting
  structure is relatively expensive, we want to allow a third party to do the vetting whereby the RA's
  are associated with this third party.

  Scenario: Setup of the institution configuration and test users
     Given I have the payload
        """
        {
            "stepup.example.com": {
                "use_ra_locations": true,
                "show_raa_contact_information": true,
                "verify_email": true,
                "self_vet": false,
                "allowed_second_factors": [],
                "number_of_tokens_per_identity": 2
            },
            "institution-a.example.com": {
                "use_ra_locations": true,
                "show_raa_contact_information": true,
                "verify_email": true,
                "self_vet": false,
                "allowed_second_factors": [],
                "number_of_tokens_per_identity": 1,
                "use_ra": [
                    "stepup.example.com"
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
                    "stepup.example.com"
                ]
            },
            "institution-e.example.com": {
                "use_ra_locations": true,
                "show_raa_contact_information": true,
                "verify_email": true,
                "self_vet": false,
                "allowed_second_factors": [],
                "number_of_tokens_per_identity": 1,
                "use_ra": [
                    "stepup.example.com"
                ]
            }
        }
        """
      And I authenticate to the Middleware API
      And I request "POST /management/institution-configuration"
      And a user "Usain Sergei" identified by "urn:collab:person:stepup.example.com:joe--ra" from institution "stepup.example.com"
      And the user "urn:collab:person:stepup.example.com:joe--ra" has a vetted "yubikey" with identifier "00000004"
      And the user "urn:collab:person:stepup.example.com:joe--ra" has the role "ra" for institution "stepup.example.com"
      And a user "Jane Jackson" identified by "urn:collab:person:institution-a.example.com:jane-a1" from institution "institution-a.example.com"
      And the user "urn:collab:person:institution-a.example.com:jane-a1" has a vetted "yubikey" with identifier "00000005"
      And a user "Joe Satriani" identified by "urn:collab:person:institution-d.example.com:joe-d1" from institution "institution-d.example.com"
      And the user "urn:collab:person:institution-d.example.com:joe-d1" has a verified "yubikey" with registration code "1234ABCD"
      And a user "Joe Perry" identified by "urn:collab:person:institution-e.example.com:joe-e1" from institution "institution-e.example.com"
      And the user "urn:collab:person:institution-e.example.com:joe-e1" has a verified "yubikey" with registration code "9876WXYZ"

  Scenario: The third party RA user can vet tokens from other institutions
    Given I am logged in into the ra portal as "joe--ra" with a "yubikey" token
     When I search for "1234ABCD" on the token activation page
     Then I should see "Please connect the user's personal Yubikey with your computer"
     When I search for "9876WXYZ" on the token activation page
     Then I should see "Please connect the user's personal Yubikey with your computer"
