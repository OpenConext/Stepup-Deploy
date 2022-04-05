Feature: Use case D: Vetting users from a guest IdP
  Allow users from a "guest" IdP (i.e. an IdP for users that do not have a relation with an institution that
  warrants adding them to the institutional IdP) to be vetted. The RA(A)s to do this will necessarily need to belong to
  another institution. The guest IdP itself does not have RAs or RAAs.
  In this context:
   - institution-a.example.com = Guest IdP
   - institution-b.example.com = Vetting service
   - institution-d.example.com = Vetting service

  Scenario: Setup of the institution configuration and test users - option 1
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
                    "institution-b.example.com"
                ],
                "use_raa": [
                    "institution-b.example.com"
                ],
                "select_raa": []
            },
            "institution-b.example.com": {
                "use_ra_locations": true,
                "show_raa_contact_information": true,
                "verify_email": true,
                "self_vet": false,
                "allowed_second_factors": [],
                "number_of_tokens_per_identity": 1
            }
        }
        """
     And I authenticate to the Middleware API
     And I request "POST /management/institution-configuration"

  Scenario: Setup of the institution configuration and test users - option 2
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
                "select_raa": [
                    "institution-b.example.com"
                ]
            },
            "institution-b.example.com": {
                "use_ra_locations": true,
                "show_raa_contact_information": true,
                "verify_email": true,
                "self_vet": false,
                "allowed_second_factors": [],
                "number_of_tokens_per_identity": 1
            }
        }
        """
     And I authenticate to the Middleware API
     And I request "POST /management/institution-configuration"
