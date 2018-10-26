# Howto: configure a dummy GSSP

This section describes how the [GSSP example application](https://github.com/OpenConext/Stepup-gssp-example/) can be used in Stepup to test the GSSP mechanism. Below configuration allows registration and authentication on the development environment using Tiqr as second factor, using the GSSP example application instead of a real tiqr implementation.

These instructions are based on [Add GSSP to Stepup readme](add-gssf-to-stepup.md).

First, install, configure and run the example application. You can do that in the VM, but that's not required. Doing it on your host machine with only PHP installed might be easier.

    git clone https://github.com/OpenConext/Stepup-gssp-example.git
    cd Stepup-gssp-example
    composer install

Now configure gateway as the remote SP in `app/config/parameters.yml`:


    saml_idp_publickey: '%kernel.root_dir%/../vendor/surfnet/stepup-saml-bundle/src/Resources/keys/development_publickey.cer'
    saml_idp_privatekey: '%kernel.root_dir%/../vendor/surfnet/stepup-saml-bundle/src/Resources/keys/development_privatekey.pem'
    saml_metadata_publickey: '%kernel.root_dir%/../vendor/surfnet/stepup-saml-bundle/src/Resources/keys/development_publickey.cer'
    saml_metadata_privatekey: '%kernel.root_dir%/../vendor/surfnet/stepup-saml-bundle/src/Resources/keys/development_privatekey.pem'
    saml_remote_sp_entity_id: 'https://gateway.stepup.example.com/gssp/dummy/metadata'
    saml_remote_sp_sso_url: 'https://gateway.stepup.example.com/gssp/dummy/single-sign-on'
    saml_remote_sp_certificate: '%kernel.root_dir%/../vendor/surfnet/stepup-saml-bundle/src/Resources/keys/development_publickey.cer'
    saml_remote_sp_acs: 'https://gateway.stepup.example.com/gssp/dummy/consume-assertion'

Finally, compile the assets and run the example application:

    composer encore dev
    cd web
    php -S localhost:1234

    TODO: this should be provisioned automatically on the dev VM, not depending on the host machine!

Note: You need npm and yarn installed on the machine you're running the example application on. An alternative is using the Vagrantfile included in the GSSP example repository.

Verify the GSSP example application is running without error on http://localhost:1234.

Now configure `Stepup-Gateway/app/config/samlstepupproviders_parameters.yml`:

    gssp_allowed_sps:
        - 'https://selfservice.stepup.example.com/registration/gssf/tiqr/metadata'
        - 'https://ra.stepup.example.com/vetting-procedure/gssf/tiqr/metadata'
        - 'https://selfservice.stepup.example.com/registration/gssf/dummy/metadata'
        - 'https://ra.stepup.example.com/vetting-procedure/gssf/dummy/metadata'

    gssp_dummy_enabled: true
    gssp_dummy_sp_publickey: /src/Stepup-Gateway/vendor/surfnet/stepup-saml-bundle/src/Resources/keys/development_publickey.cer
    gssp_dummy_sp_privatekey: /src/Stepup-Gateway/vendor/surfnet/stepup-saml-bundle/src/Resources/keys/development_privatekey.pem
    gssp_dummy_idp_publickey: /src/Stepup-Gateway/vendor/surfnet/stepup-saml-bundle/src/Resources/keys/development_publickey.cer
    gssp_dummy_idp_privatekey: /src/Stepup-Gateway/vendor/surfnet/stepup-saml-bundle/src/Resources/keys/development_privatekey.pem
    gssp_dummy_metadata_publickey: /src/Stepup-Gateway/vendor/surfnet/stepup-saml-bundle/src/Resources/keys/development_publickey.cer
    gssp_dummy_metadata_privatekey: /src/Stepup-Gateway/vendor/surfnet/stepup-saml-bundle/src/Resources/keys/development_privatekey.pem
    gssp_dummy_remote_entity_id: 'http://localhost:1234/app_dev.php/saml/metadata'
    gssp_dummy_remote_sso_url: 'http://localhost:1234/app_dev.php/saml/sso'
    gssp_dummy_remote_certificate: |
                                   MIIEJTCCAw2gAwIBAgIJANug+o++1X5IMA0GCSqGSIb3DQEBCwUAMIGoMQswCQYD
                                   VQQGEwJOTDEQMA4GA1UECAwHVXRyZWNodDEQMA4GA1UEBwwHVXRyZWNodDEVMBMG
                                   A1UECgwMU1VSRm5ldCBCLlYuMRMwEQYDVQQLDApTVVJGY29uZXh0MRwwGgYDVQQD
                                   DBNTVVJGbmV0IERldmVsb3BtZW50MSswKQYJKoZIhvcNAQkBFhxzdXJmY29uZXh0
                                   LWJlaGVlckBzdXJmbmV0Lm5sMB4XDTE0MTAyMDEyMzkxMVoXDTE0MTExOTEyMzkx
                                   MVowgagxCzAJBgNVBAYTAk5MMRAwDgYDVQQIDAdVdHJlY2h0MRAwDgYDVQQHDAdV
                                   dHJlY2h0MRUwEwYDVQQKDAxTVVJGbmV0IEIuVi4xEzARBgNVBAsMClNVUkZjb25l
                                   eHQxHDAaBgNVBAMME1NVUkZuZXQgRGV2ZWxvcG1lbnQxKzApBgkqhkiG9w0BCQEW
                                   HHN1cmZjb25leHQtYmVoZWVyQHN1cmZuZXQubmwwggEiMA0GCSqGSIb3DQEBAQUA
                                   A4IBDwAwggEKAoIBAQDXuSSBeNJY3d4p060oNRSuAER5nLWT6AIVbv3XrXhcgSwc
                                   9m2b8u3ksp14pi8FbaNHAYW3MjlKgnLlopYIylzKD/6Ut/clEx67aO9Hpqsc0HmI
                                   P0It6q2bf5yUZ71E4CN2HtQceO5DsEYpe5M7D5i64kS2A7e2NYWVdA5Z01DqUpQG
                                   RBc+uMzOwyif6StBiMiLrZH3n2r5q5aVaXU4Vy5EE4VShv3Mp91sgXJj/v155fv0
                                   wShgl681v8yf2u2ZMb7NKnQRA4zM2Ng2EUAyy6PQ+Jbn+rALSm1YgiJdVuSlTLhv
                                   gwbiHGO2XgBi7bTHhlqSrJFK3Gs4zwIsop/XqQRBAgMBAAGjUDBOMB0GA1UdDgQW
                                   BBQCJmcoa/F7aM3jIFN7Bd4uzWRgzjAfBgNVHSMEGDAWgBQCJmcoa/F7aM3jIFN7
                                   Bd4uzWRgzjAMBgNVHRMEBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQBd80GpWKjp
                                   1J+Dgp0blVAox1s/WPWQlex9xrx1GEYbc5elp3svS+S82s7dFm2llHrrNOBt1HZV
                                   C+TdW4f+MR1xq8O5lOYjDRsosxZc/u9jVsYWYc3M9bQAx8VyJ8VGpcAK+fLqRNab
                                   YlqTnj/t9bzX8fS90sp8JsALV4g84Aj0G8RpYJokw+pJUmOpuxsZN5U84MmLPnVf
                                   mrnuCVh/HkiLNV2c8Pk8LSomg6q1M1dQUTsz/HVxcOhHLj/owwh3IzXf/KXV/E8v
                                   SYW8o4WWCAnruYOWdJMI4Z8NG1Mfv7zvb7U3FL1C/KLV04DqzALXGj+LVmxtDvux
                                   qC042apoIDQV
    gssp_dummy_logo: /tiqr.jpg
    gssp_dummy_title:
        en_GB: Dummy
        nl_NL: Dummy

And configure `Stepup-Gateway/app/config/samlstepupproviders.yml`:

        dummy:
            enabled: %gssp_dummy_enabled%
            hosted:
                service_provider:
                    public_key: %gssp_dummy_sp_publickey%
                    private_key: %gssp_dummy_sp_privatekey%
                identity_provider:
                    service_provider_repository: saml.entity_repository
                    public_key: %gssp_dummy_idp_publickey%
                    private_key: %gssp_dummy_idp_privatekey%
                metadata:
                    public_key: %gssp_dummy_metadata_publickey%
                    private_key: %gssp_dummy_metadata_privatekey%
            remote:
                entity_id: %gssp_dummy_remote_entity_id%
                sso_url: %gssp_dummy_remote_sso_url%
                certificate: %gssp_dummy_remote_certificate%
            view_config:
                logo: %gssp_dummy_logo%
                title: %gssp_dummy_title%


And configure `Stepup-Gateway/app/config/parameters.yml`:

    enabled_generic_second_factors:
        tiqr:
            loa: 2
        dummy:
            loa: 2

No on to SelfService, configure `Stepup-SelfService/app/config/samlstepupproviders_parameters.yml`:

    gssp_dummy_sp_publickey: /src/Stepup-Gateway/vendor/surfnet/stepup-saml-bundle/src/Resources/keys/development_publickey.cer
    gssp_dummy_sp_privatekey: /src/Stepup-Gateway/vendor/surfnet/stepup-saml-bundle/src/Resources/keys/development_privatekey.pem
    gssp_dummy_idp_publickey: /src/Stepup-Gateway/vendor/surfnet/stepup-saml-bundle/src/Resources/keys/development_publickey.cer
    gssp_dummy_idp_privatekey: /src/Stepup-Gateway/vendor/surfnet/stepup-saml-bundle/src/Resources/keys/development_privatekey.pem
    gssp_dummy_metadata_publickey: /src/Stepup-Gateway/vendor/surfnet/stepup-saml-bundle/src/Resources/keys/development_publickey.cer
    gssp_dummy_metadata_privatekey: /src/Stepup-Gateway/vendor/surfnet/stepup-saml-bundle/src/Resources/keys/development_privatekey.pem
    gssp_dummy_remote_entity_id: 'https://gateway.stepup.example.com/gssp/dummy/metadata'
    gssp_dummy_remote_sso_url: 'https://gateway.stepup.example.com/gssp/dummy/single-sign-on'
    gssp_dummy_remote_certificate: |
                                   MIIEJTCCAw2gAwIBAgIJANug+o++1X5IMA0GCSqGSIb3DQEBCwUAMIGoMQswCQYD
                                   VQQGEwJOTDEQMA4GA1UECAwHVXRyZWNodDEQMA4GA1UEBwwHVXRyZWNodDEVMBMG
                                   A1UECgwMU1VSRm5ldCBCLlYuMRMwEQYDVQQLDApTVVJGY29uZXh0MRwwGgYDVQQD
                                   DBNTVVJGbmV0IERldmVsb3BtZW50MSswKQYJKoZIhvcNAQkBFhxzdXJmY29uZXh0
                                   LWJlaGVlckBzdXJmbmV0Lm5sMB4XDTE0MTAyMDEyMzkxMVoXDTE0MTExOTEyMzkx
                                   MVowgagxCzAJBgNVBAYTAk5MMRAwDgYDVQQIDAdVdHJlY2h0MRAwDgYDVQQHDAdV
                                   dHJlY2h0MRUwEwYDVQQKDAxTVVJGbmV0IEIuVi4xEzARBgNVBAsMClNVUkZjb25l
                                   eHQxHDAaBgNVBAMME1NVUkZuZXQgRGV2ZWxvcG1lbnQxKzApBgkqhkiG9w0BCQEW
                                   HHN1cmZjb25leHQtYmVoZWVyQHN1cmZuZXQubmwwggEiMA0GCSqGSIb3DQEBAQUA
                                   A4IBDwAwggEKAoIBAQDXuSSBeNJY3d4p060oNRSuAER5nLWT6AIVbv3XrXhcgSwc
                                   9m2b8u3ksp14pi8FbaNHAYW3MjlKgnLlopYIylzKD/6Ut/clEx67aO9Hpqsc0HmI
                                   P0It6q2bf5yUZ71E4CN2HtQceO5DsEYpe5M7D5i64kS2A7e2NYWVdA5Z01DqUpQG
                                   RBc+uMzOwyif6StBiMiLrZH3n2r5q5aVaXU4Vy5EE4VShv3Mp91sgXJj/v155fv0
                                   wShgl681v8yf2u2ZMb7NKnQRA4zM2Ng2EUAyy6PQ+Jbn+rALSm1YgiJdVuSlTLhv
                                   gwbiHGO2XgBi7bTHhlqSrJFK3Gs4zwIsop/XqQRBAgMBAAGjUDBOMB0GA1UdDgQW
                                   BBQCJmcoa/F7aM3jIFN7Bd4uzWRgzjAfBgNVHSMEGDAWgBQCJmcoa/F7aM3jIFN7
                                   Bd4uzWRgzjAMBgNVHRMEBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQBd80GpWKjp
                                   1J+Dgp0blVAox1s/WPWQlex9xrx1GEYbc5elp3svS+S82s7dFm2llHrrNOBt1HZV
                                   C+TdW4f+MR1xq8O5lOYjDRsosxZc/u9jVsYWYc3M9bQAx8VyJ8VGpcAK+fLqRNab
                                   YlqTnj/t9bzX8fS90sp8JsALV4g84Aj0G8RpYJokw+pJUmOpuxsZN5U84MmLPnVf
                                   mrnuCVh/HkiLNV2c8Pk8LSomg6q1M1dQUTsz/HVxcOhHLj/owwh3IzXf/KXV/E8v
                                   SYW8o4WWCAnruYOWdJMI4Z8NG1Mfv7zvb7U3FL1C/KLV04DqzALXGj+LVmxtDvux
                                   qC042apoIDQV
    gssp_dummy_loa: 2
    gssp_dummy_logo: /images/second-factor/dummy.png
    gssp_dummy_alt:
        en_GB: Dummy
        nl_NL: Dummy
    gssp_dummy_title:
        en_GB: Dummy
        nl_NL: Dummy
    gssp_dummy_description:
        en_GB: 'Log in with a smartphone app. For all smartphones with %%ios_link_start%%Apple iOS%%ios_link_end%% or %%android_link_start%%Android%%android_link_end%%.'
        nl_NL: 'Log in met een app op je smartphone. Geschikt voor smartphones met %%ios_link_start%%Apple iOS%%ios_link_end%% of %%android_link_start%%Android%%android_link_end%%.'
    gssp_dummy_app_android_url: 'https://example.com/dummy/android'
    gssp_dummy_app_ios_url: 'https://example.com/dummy/ios'
    gssp_dummy_button_use:
        en_GB: Select
        nl_NL: Selecteer
    gssp_dummy_initiate_title:
        en_GB: 'Register with Dummy'
        nl_NL: 'Registreren bij Dummy'
    gssp_dummy_initiate_button:
        en_GB: 'Register with Dummy'
        nl_NL: 'Registreer bij Dummy'
    gssp_dummy_explanation:
        en_GB: 'Click the button below to register with Dummy.'
        nl_NL: 'Klik op de knop hieronder om je bij Dummy te registreren.'
    gssp_dummy_authn_failed:
        en_GB: 'Registration with Dummy has failed. Please try again.'
        nl_NL: 'Registratie bij Dummy is mislukt. Probeer het nogmaals.'
    gssp_dummy_pop_failed:
        en_GB: 'Registration of your token failed. Please try again.'
        nl_NL: 'De registratie van uw token is mislukt. Probeer het nogmaals.'

And in SelfService, configure `Stepup-SelfService/app/config/samlstepupproviders.yml`:

        dummy:
            hosted:
                service_provider:
                    public_key: %gssp_dummy_sp_publickey%
                    private_key: %gssp_dummy_sp_privatekey%
                metadata:
                    public_key: %gssp_dummy_metadata_publickey%
                    private_key: %gssp_dummy_metadata_privatekey%
            remote:
                entity_id: %gssp_dummy_remote_entity_id%
                sso_url: %gssp_dummy_remote_sso_url%
                certificate: %gssp_dummy_remote_certificate%
            view_config:
                loa: %gssp_dummy_loa%
                logo: %gssp_dummy_logo%
                alt: %gssp_dummy_alt%
                title: %gssp_dummy_title%
                description: %gssp_dummy_description%
                button_use: %gssp_dummy_button_use%
                initiate_title: %gssp_dummy_initiate_title%
                initiate_button: %gssp_dummy_initiate_button%
                explanation: %gssp_dummy_initiate_title%
                authn_failed: %gssp_dummy_authn_failed%
                pop_failed: %gssp_dummy_pop_failed%
                app_android_url: %gssp_dummy_app_android_url%
                app_ios_url: %gssp_dummy_app_ios_url%

And configure `Stepup-SelfService/app/config/parameters.yml`:

    enabled_generic_second_factors:
        tiqr:
            loa: 2
        dummy:
            loa: 2

On to RA, configure `Stepup-RA/app/config/samlstepupproviders_parameters.yml`:

    gssp_dummy_sp_publickey: '%kernel.root_dir%/../vendor/surfnet/stepup-saml-bundle/src/Resources/keys/development_publickey.cer'
    gssp_dummy_sp_privatekey: '%kernel.root_dir%/../vendor/surfnet/stepup-saml-bundle/src/Resources/keys/development_privatekey.pem'
    gssp_dummy_metadata_publickey: '%kernel.root_dir%/../vendor/surfnet/stepup-saml-bundle/src/Resources/keys/development_publickey.cer'
    gssp_dummy_metadata_privatekey: '%kernel.root_dir%/../vendor/surfnet/stepup-saml-bundle/src/Resources/keys/development_privatekey.pem'
    gssp_dummy_remote_entity_id: 'https://gateway.stepup.example.com/gssp/dummy/metadata'
    gssp_dummy_remote_sso_url: 'https://gateway.stepup.example.com/gssp/dummy/single-sign-on'
    gssp_dummy_remote_certificate: |
                                   MIIEJTCCAw2gAwIBAgIJANug+o++1X5IMA0GCSqGSIb3DQEBCwUAMIGoMQswCQYD
                                   VQQGEwJOTDEQMA4GA1UECAwHVXRyZWNodDEQMA4GA1UEBwwHVXRyZWNodDEVMBMG
                                   A1UECgwMU1VSRm5ldCBCLlYuMRMwEQYDVQQLDApTVVJGY29uZXh0MRwwGgYDVQQD
                                   DBNTVVJGbmV0IERldmVsb3BtZW50MSswKQYJKoZIhvcNAQkBFhxzdXJmY29uZXh0
                                   LWJlaGVlckBzdXJmbmV0Lm5sMB4XDTE0MTAyMDEyMzkxMVoXDTE0MTExOTEyMzkx
                                   MVowgagxCzAJBgNVBAYTAk5MMRAwDgYDVQQIDAdVdHJlY2h0MRAwDgYDVQQHDAdV
                                   dHJlY2h0MRUwEwYDVQQKDAxTVVJGbmV0IEIuVi4xEzARBgNVBAsMClNVUkZjb25l
                                   eHQxHDAaBgNVBAMME1NVUkZuZXQgRGV2ZWxvcG1lbnQxKzApBgkqhkiG9w0BCQEW
                                   HHN1cmZjb25leHQtYmVoZWVyQHN1cmZuZXQubmwwggEiMA0GCSqGSIb3DQEBAQUA
                                   A4IBDwAwggEKAoIBAQDXuSSBeNJY3d4p060oNRSuAER5nLWT6AIVbv3XrXhcgSwc
                                   9m2b8u3ksp14pi8FbaNHAYW3MjlKgnLlopYIylzKD/6Ut/clEx67aO9Hpqsc0HmI
                                   P0It6q2bf5yUZ71E4CN2HtQceO5DsEYpe5M7D5i64kS2A7e2NYWVdA5Z01DqUpQG
                                   RBc+uMzOwyif6StBiMiLrZH3n2r5q5aVaXU4Vy5EE4VShv3Mp91sgXJj/v155fv0
                                   wShgl681v8yf2u2ZMb7NKnQRA4zM2Ng2EUAyy6PQ+Jbn+rALSm1YgiJdVuSlTLhv
                                   gwbiHGO2XgBi7bTHhlqSrJFK3Gs4zwIsop/XqQRBAgMBAAGjUDBOMB0GA1UdDgQW
                                   BBQCJmcoa/F7aM3jIFN7Bd4uzWRgzjAfBgNVHSMEGDAWgBQCJmcoa/F7aM3jIFN7
                                   Bd4uzWRgzjAMBgNVHRMEBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQBd80GpWKjp
                                   1J+Dgp0blVAox1s/WPWQlex9xrx1GEYbc5elp3svS+S82s7dFm2llHrrNOBt1HZV
                                   C+TdW4f+MR1xq8O5lOYjDRsosxZc/u9jVsYWYc3M9bQAx8VyJ8VGpcAK+fLqRNab
                                   YlqTnj/t9bzX8fS90sp8JsALV4g84Aj0G8RpYJokw+pJUmOpuxsZN5U84MmLPnVf
                                   mrnuCVh/HkiLNV2c8Pk8LSomg6q1M1dQUTsz/HVxcOhHLj/owwh3IzXf/KXV/E8v
                                   SYW8o4WWCAnruYOWdJMI4Z8NG1Mfv7zvb7U3FL1C/KLV04DqzALXGj+LVmxtDvux
                                   qC042apoIDQV
    gssp_dummy_title:
        en_GB: Dummy
        nl_NL: Dummy
    gssp_dummy_page_title:
        en_GB: 'Verify with Dummy'
        nl_NL: 'Dummy verifiëren'
    gssp_dummy_explanation:
        en_GB: 'Click the button below to verify the registrant owns the Dummy account he or she registered with in the Self-Service application.'
        nl_NL: 'Klik de knop hieronder om te verifiëren dat de registrant het Dummy-account bezit dat hij of zij gebruikt heeft in de Self-Service-applicatie.'
    gssp_dummy_initiate:
        en_GB: 'Verify with Dummy'
        nl_NL: 'Verifiëren bij Dummy'
    gssp_dummy_gssf_id_mismatch:
        en_GB: 'ID mismatch'
        nl_NL: 'ID mismatch'

And configure `Stepup-RA/app/config/samlstepupproviders.yml`:

        dummy:
            hosted:
                service_provider:
                    public_key: %gssp_dummy_sp_publickey%
                    private_key: %gssp_dummy_sp_privatekey%
                metadata:
                    public_key: %gssp_dummy_metadata_publickey%
                    private_key: %gssp_dummy_metadata_privatekey%
            remote:
                entity_id: %gssp_dummy_remote_entity_id%
                sso_url: %gssp_dummy_remote_sso_url%
                certificate: %gssp_dummy_remote_certificate%
            view_config:
                title: %gssp_dummy_title%
                page_title: %gssp_dummy_page_title%
                explanation: %gssp_dummy_explanation%
                initiate: %gssp_dummy_initiate%
                gssf_id_mismatch: %gssp_dummy_gssf_id_mismatch%

Also, configure `Stepup-RA/app/config/parameters.yml`:

    enabled_generic_second_factors:
        tiqr:
            loa: 2
        dummy:
            loa: 2

Now configure `Stepup-Middleware/app/config/parameters.yml`:

    enabled_generic_second_factors:
        biometric:
            loa: 3
        tiqr:
            loa: 2
        dummy:
            loa: 2

Add 'dummy' to 'allowed_second_factors' in the institution configuration for the stepup.example.com organisation, and push the middleware configuration. Hacking this on the VM looks like this:

    sudo -s
    cd /opt/scripts
    vi middleware-institution.json
    ./middleware-push-institution.sh

And finnaly, add dummy as GSSP method to the middleware config:

    sudo -s
    vi middleware-config.json

        "gateway": {
            "service_providers": [
                //...
                {
                    "entity_id": "https://selfservice.stepup.example.com/registration/gssf/dummy/metadata",
                    "public_key": "MIIEJTCCAw2gAwIBAgIJANug+o++1X5IMA0GCSqGSIb3DQEBCwUAMIGoMQswCQYDVQQGEwJOTDEQMA4GA1UECAwHVXRyZWNodDEQMA4GA1UEBwwHVXRyZWNodDEVMBMGA1UECgwMU1VSRm5ldCBCLlYuMRMwEQYDVQQLDApTVVJGY29uZXh0MRwwGgYDVQQDDBNTVVJGbmV0IERldmVsb3BtZW50MSswKQYJKoZIhvcNAQkBFhxzdXJmY29uZXh0LWJlaGVlckBzdXJmbmV0Lm5sMB4XDTE0MTAyMDEyMzkxMVoXDTE0MTExOTEyMzkxMVowgagxCzAJBgNVBAYTAk5MMRAwDgYDVQQIDAdVdHJlY2h0MRAwDgYDVQQHDAdVdHJlY2h0MRUwEwYDVQQKDAxTVVJGbmV0IEIuVi4xEzARBgNVBAsMClNVUkZjb25leHQxHDAaBgNVBAMME1NVUkZuZXQgRGV2ZWxvcG1lbnQxKzApBgkqhkiG9w0BCQEWHHN1cmZjb25leHQtYmVoZWVyQHN1cmZuZXQubmwwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDXuSSBeNJY3d4p060oNRSuAER5nLWT6AIVbv3XrXhcgSwc9m2b8u3ksp14pi8FbaNHAYW3MjlKgnLlopYIylzKD/6Ut/clEx67aO9Hpqsc0HmIP0It6q2bf5yUZ71E4CN2HtQceO5DsEYpe5M7D5i64kS2A7e2NYWVdA5Z01DqUpQGRBc+uMzOwyif6StBiMiLrZH3n2r5q5aVaXU4Vy5EE4VShv3Mp91sgXJj/v155fv0wShgl681v8yf2u2ZMb7NKnQRA4zM2Ng2EUAyy6PQ+Jbn+rALSm1YgiJdVuSlTLhvgwbiHGO2XgBi7bTHhlqSrJFK3Gs4zwIsop/XqQRBAgMBAAGjUDBOMB0GA1UdDgQWBBQCJmcoa/F7aM3jIFN7Bd4uzWRgzjAfBgNVHSMEGDAWgBQCJmcoa/F7aM3jIFN7Bd4uzWRgzjAMBgNVHRMEBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQBd80GpWKjp1J+Dgp0blVAox1s/WPWQlex9xrx1GEYbc5elp3svS+S82s7dFm2llHrrNOBt1HZVC+TdW4f+MR1xq8O5lOYjDRsosxZc/u9jVsYWYc3M9bQAx8VyJ8VGpcAK+fLqRNabYlqTnj/t9bzX8fS90sp8JsALV4g84Aj0G8RpYJokw+pJUmOpuxsZN5U84MmLPnVfmrnuCVh/HkiLNV2c8Pk8LSomg6q1M1dQUTsz/HVxcOhHLj/owwh3IzXf/KXV/E8vSYW8o4WWCAnruYOWdJMI4Z8NG1Mfv7zvb7U3FL1C/KLV04DqzALXGj+LVmxtDvuxqC042apoIDQV",
                    "acs": [
                        "https://selfservice.stepup.example.com/registration/gssf/dummy/consume-assertion"
                    ],
                    "loa": {
                        "__default__": "https://stepup.example.com/assurance/loa2"
                    },
                    "assertion_encryption_enabled": false,
                    "blacklisted_encryption_algorithms": [],
                    "second_factor_only": false,
                    "second_factor_only_nameid_patterns": []
                },
                {
                    "entity_id": "https://ra.stepup.example.com/vetting-procedure/gssf/dummy/metadata",
                    "public_key": "MIIEJTCCAw2gAwIBAgIJANug+o++1X5IMA0GCSqGSIb3DQEBCwUAMIGoMQswCQYDVQQGEwJOTDEQMA4GA1UECAwHVXRyZWNodDEQMA4GA1UEBwwHVXRyZWNodDEVMBMGA1UECgwMU1VSRm5ldCBCLlYuMRMwEQYDVQQLDApTVVJGY29uZXh0MRwwGgYDVQQDDBNTVVJGbmV0IERldmVsb3BtZW50MSswKQYJKoZIhvcNAQkBFhxzdXJmY29uZXh0LWJlaGVlckBzdXJmbmV0Lm5sMB4XDTE0MTAyMDEyMzkxMVoXDTE0MTExOTEyMzkxMVowgagxCzAJBgNVBAYTAk5MMRAwDgYDVQQIDAdVdHJlY2h0MRAwDgYDVQQHDAdVdHJlY2h0MRUwEwYDVQQKDAxTVVJGbmV0IEIuVi4xEzARBgNVBAsMClNVUkZjb25leHQxHDAaBgNVBAMME1NVUkZuZXQgRGV2ZWxvcG1lbnQxKzApBgkqhkiG9w0BCQEWHHN1cmZjb25leHQtYmVoZWVyQHN1cmZuZXQubmwwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDXuSSBeNJY3d4p060oNRSuAER5nLWT6AIVbv3XrXhcgSwc9m2b8u3ksp14pi8FbaNHAYW3MjlKgnLlopYIylzKD/6Ut/clEx67aO9Hpqsc0HmIP0It6q2bf5yUZ71E4CN2HtQceO5DsEYpe5M7D5i64kS2A7e2NYWVdA5Z01DqUpQGRBc+uMzOwyif6StBiMiLrZH3n2r5q5aVaXU4Vy5EE4VShv3Mp91sgXJj/v155fv0wShgl681v8yf2u2ZMb7NKnQRA4zM2Ng2EUAyy6PQ+Jbn+rALSm1YgiJdVuSlTLhvgwbiHGO2XgBi7bTHhlqSrJFK3Gs4zwIsop/XqQRBAgMBAAGjUDBOMB0GA1UdDgQWBBQCJmcoa/F7aM3jIFN7Bd4uzWRgzjAfBgNVHSMEGDAWgBQCJmcoa/F7aM3jIFN7Bd4uzWRgzjAMBgNVHRMEBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQBd80GpWKjp1J+Dgp0blVAox1s/WPWQlex9xrx1GEYbc5elp3svS+S82s7dFm2llHrrNOBt1HZVC+TdW4f+MR1xq8O5lOYjDRsosxZc/u9jVsYWYc3M9bQAx8VyJ8VGpcAK+fLqRNabYlqTnj/t9bzX8fS90sp8JsALV4g84Aj0G8RpYJokw+pJUmOpuxsZN5U84MmLPnVfmrnuCVh/HkiLNV2c8Pk8LSomg6q1M1dQUTsz/HVxcOhHLj/owwh3IzXf/KXV/E8vSYW8o4WWCAnruYOWdJMI4Z8NG1Mfv7zvb7U3FL1C/KLV04DqzALXGj+LVmxtDvuxqC042apoIDQV",
                    "acs": [
                        "https://ra.stepup.example.com/vetting-procedure/gssf/dummy/verify"
                    ],
                    "loa": {
                        "__default__": "https://stepup.example.com/assurance/loa2"
                    },
                    "assertion_encryption_enabled": false,
                    "blacklisted_encryption_algorithms": [],
                    "second_factor_only": false,
                    "second_factor_only_nameid_patterns": []
                },

And push the config:

    ./middleware-push-config.sh

You should now be able to register a dummy token in selfservice, vet it in RA and use it for authentication.
