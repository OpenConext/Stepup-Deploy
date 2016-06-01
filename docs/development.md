# Development setup
Make sure all of the applications and their dependencies have been installed correctly, configure the correct parameters
and follow the installation instructions for each application.

Accounts can be added to the `$config` in your git-ignored `simplesamlphp/config/authsources.php` file. 
For development purposes, it could be useful to add the SRAA, RAA and RA accounts:

```php
    ...
        'sraa:sraa' => array(
            'commonName'             => 'SRAA',                 // displayName
            'mail'                    => 'sraa@sraa.example',   // email (also used for EPTI)
            'schacHomeOrganization'   => 'Example Inc',         // schacHomeOrganisation
        ),
        'raa:raa' => array(
            'commonName'             => 'RAA',                  // displayName
            'mail'                    => 'raa@raa.example',     // email (also used for EPTI)
            'schacHomeOrganization'   => 'Example Inc',         // schacHomeOrganisation
        ),
        'ra:ra' => array(
            'commonName'             => 'RA',                   // displayName
            'mail'                    => 'ra@ra.example',       // email (also used for EPTI)
            'schacHomeOrganization'   => 'Example Inc',         // schacHomeOrganisation
        )
    ...
```

To whitelist the organisation of these accounts, use the [Middleware Manager API][middleware-manager]:

```
    POST /app_dev.php/management/whitelist/add HTTP/1.1
     Host: mw-dev.stepup.coin.surf.net
     Accept: application/json
     Content-Type: application/json
     Authorization: Basic bWFuYWdlbWVudDpiYXI=
     Cache-Control: no-cache

     {
       "institutions": [
         "Example Inc"
       ]
     }
```

To allow account `sraa` to be added as an SRAA, use the [Middleware Manager API][middleware-manager] (request body has been truncated) to configure
its NameID as such: 

```
      POST /app_dev.php/management/configuration HTTP/1.1
      Host: mw-dev.stepup.coin.surf.net
      Accept: application/json
      Content-Type: application/json
      Authorization: Basic bWFuYWdlbWVudDpiYXI=
      Cache-Control: no-cache

      {
          "sraa": [
            "9971dbcf01267b11f6107d9cafb43e5b4009a955"
          ],
          ...
      }
```

To add account `sraa` by its NameID as an SRAA, run the following for Stepup-Middleware, replacing `<YOUR_YUBIKEY_NUMBER>` 
with the number relating to your Yubikey (it is usually printed on it):

```
    app/console middleware:bootstrap:identity-with-yubikey 9971dbcf01267b11f6107d9cafb43e5b4009a955 'Example Inc' 'SRAA' sraa@sraa.example nl_NL <YOUR_YUBIKEY_NUMBER>
```

To add `raa` and `ra` as RAA and RA respectively, they first have to go through the vetting process.
Their verification tokens can be registered by `sraa` in RA. The accounts can then also be added as an RAA or RA.

Make sure RAA's and RA's are registered conform the LoA required for RA (loa3 by default). 

The LoA required for RA is configured in Stepup-RA's `parameters.yml` and through the [Middleware Manager API][middleware-manager]: 

```
    POST /app_dev.php/management/configuration HTTP/1.1
    Host: mw-dev.stepup.coin.surf.net
    Accept: application/json
    Content-Type: application/json
    Authorization: Basic bWFuYWdlbWVudDpiYXI=
    Cache-Control: no-cache

    "gateway": {
        "identity_providers": [],
        "service_providers": [
            ...
            {
               "entity_id": "https://ra-dev.stepup.coin.surf.net/app_dev.php/authentication/metadata",
               "public_key": "MIIEJTCCAw2gAwIBAgIJANug+o++1X5IMA0GCSqGSIb3DQEBCwUAMIGoMQswCQYDVQQGEwJOTDEQMA4GA1UECAwHVXRyZWNodDEQMA4GA1UEBwwHVXRyZWNodDEVMBMGA1UECgwMU1VSRm5ldCBCLlYuMRMwEQYDVQQLDApTVVJGY29uZXh0MRwwGgYDVQQDDBNTVVJGbmV0IERldmVsb3BtZW50MSswKQYJKoZIhvcNAQkBFhxzdXJmY29uZXh0LWJlaGVlckBzdXJmbmV0Lm5sMB4XDTE0MTAyMDEyMzkxMVoXDTE0MTExOTEyMzkxMVowgagxCzAJBgNVBAYTAk5MMRAwDgYDVQQIDAdVdHJlY2h0MRAwDgYDVQQHDAdVdHJlY2h0MRUwEwYDVQQKDAxTVVJGbmV0IEIuVi4xEzARBgNVBAsMClNVUkZjb25leHQxHDAaBgNVBAMME1NVUkZuZXQgRGV2ZWxvcG1lbnQxKzApBgkqhkiG9w0BCQEWHHN1cmZjb25leHQtYmVoZWVyQHN1cmZuZXQubmwwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDXuSSBeNJY3d4p060oNRSuAER5nLWT6AIVbv3XrXhcgSwc9m2b8u3ksp14pi8FbaNHAYW3MjlKgnLlopYIylzKD/6Ut/clEx67aO9Hpqsc0HmIP0It6q2bf5yUZ71E4CN2HtQceO5DsEYpe5M7D5i64kS2A7e2NYWVdA5Z01DqUpQGRBc+uMzOwyif6StBiMiLrZH3n2r5q5aVaXU4Vy5EE4VShv3Mp91sgXJj/v155fv0wShgl681v8yf2u2ZMb7NKnQRA4zM2Ng2EUAyy6PQ+Jbn+rALSm1YgiJdVuSlTLhvgwbiHGO2XgBi7bTHhlqSrJFK3Gs4zwIsop/XqQRBAgMBAAGjUDBOMB0GA1UdDgQWBBQCJmcoa/F7aM3jIFN7Bd4uzWRgzjAfBgNVHSMEGDAWgBQCJmcoa/F7aM3jIFN7Bd4uzWRgzjAMBgNVHRMEBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQBd80GpWKjp1J+Dgp0blVAox1s/WPWQlex9xrx1GEYbc5elp3svS+S82s7dFm2llHrrNOBt1HZVC+TdW4f+MR1xq8O5lOYjDRsosxZc/u9jVsYWYc3M9bQAx8VyJ8VGpcAK+fLqRNabYlqTnj/t9bzX8fS90sp8JsALV4g84Aj0G8RpYJokw+pJUmOpuxsZN5U84MmLPnVfmrnuCVh/HkiLNV2c8Pk8LSomg6q1M1dQUTsz/HVxcOhHLj/owwh3IzXf/KXV/E8vSYW8o4WWCAnruYOWdJMI4Z8NG1Mfv7zvb7U3FL1C/KLV04DqzALXGj+LVmxtDvuxqC042apoIDQV",
               "acs": [
                    "https://ra-dev.stepup.coin.surf.net/app_dev.php/authentication/consume-assertion"
                ],
                "loa": {
                    "__default__": "https://gw-dev.stepup.coin.surf.net/authentication/loa3"
                },
                "assertion_encryption_enabled": false,
                "blacklisted_encryption_algorithms": []
            }
        ]
    }
```

[middleware-manager]: https://github.com/SURFnet/Stepup-Middleware/tree/master#management-api
