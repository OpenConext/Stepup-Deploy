Feature: Use case F: An institution that manages Stepup for a (a group of) sister and/or daughter institutions
  An institution that manages Stepup for (a group of) sister and/or daughter institutions. This use-case appears similar
  to use-case A. The differences lie in the relation that the managing institution has with the institutions being
  manged. RA(s)s could come from the sister/daughter institutions, but would be managed from the main institution.

   - institution-a.example.com = The parent institution
   - institution-b.example.com = Sister/daughter institution
   - institution-c.example.com = Sister/daughter institution

  Scenario: Setup of the institution configuration and test users
     Given I have the payload
        """
        {
            "institution-a.example.com": {
                "use_ra_locations": true,
                "show_raa_contact_information": true,
                "verify_email": true,
                "allowed_second_factors": [],
                "number_of_tokens_per_identity": 2,
                "select_raa": [
                    "institution-a.example.com",
                    "institution-b.example.com",
                    "institution-d.example.com"
                ]
            },
            "institution-b.example.com": {
                "use_ra_locations": true,
                "show_raa_contact_information": true,
                "verify_email": true,
                "allowed_second_factors": [],
                "number_of_tokens_per_identity": 1,
                "use_ra": ["institution-a.example.com"],
                "use_raa": ["institution-a.example.com"],
                "select_raa": []
            },
            "institution-d.example.com": {
                "use_ra_locations": true,
                "show_raa_contact_information": true,
                "verify_email": true,
                "allowed_second_factors": [],
                "number_of_tokens_per_identity": 1,
                "use_ra": ["institution-a.example.com"],
                "use_raa": ["institution-a.example.com"],
                "select_raa": []
            }
        }
        """
      And I authenticate to the Middleware API
      And I request "POST /management/institution-configuration"
