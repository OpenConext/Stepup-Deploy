Feature: Use case E: Institution that uses multiple SHOs
  An institution IdP that issues multiple SHOs, e.g. institution.org and some-related-part.institution.org. From the
  perspective of Stepup these would currently become multiple institutions, which each have and manage their own RA(A)s.
  This is not what the institution would want, they would want their multiple SHOs to appear as one institution
  management wise.

   - institution-a.example.com= An institution with SHO additional SHOs
   - institution-b.example.com = One of the additional SHOs
   - institution-c.example.com = One of the additional SHOs

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
