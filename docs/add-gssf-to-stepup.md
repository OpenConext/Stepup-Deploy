# Adding a new GSSP to Stepup
Since release 11 a new GSSP can be added through configuration only, no code changes are required to any of the Stepup components. This requires changes to the configuration of these components when updating to release 11.

## Ansible Playbooks

The Ansible playbooks in Stepup-Deploy were updated to work with the two GSSPs that existed prior to this release, namely: "tiqr" and "biometric". The only change required is updating the `all.yml` group_var in the Ansible environment:

1. Add `stepup_enabled_generic_second_factors`:

    ``` yaml
    stepup_enabled_generic_second_factors:
      tiqr:
        loa: 2
      biometric:
        loa: 2 
    ```

2. Update `stepup_enabled_factors`. This variable no longer control the GSSPs but controls _only_ the build-in second factor types ("yubikey", "sms" and "u2f").

If your are updating an existing configuration that is deployed using Stepup-Deploy then the two changes above are the only two required changes.

The playbooks do not (yet) support adding new GSSPs though configuration, for that the "stepup-gateway", "stetup-ra" and "stepup-selfservice" roles will need to be updated with the required "app/config/samlstepupproviders_parameters.yml".


## Configuration changes

The sections below describe the changes to the individual configuration files of the individual components. This list of changes was compiled during testing of the addition of the feature. The actual implementation is not described in this document.
 
### Stepup-Middleware

1. Add the new GSSP to: `Stepup-Middleware/app/config/parameters.yml`. Example value for the `enabled_generic_second_factors`:

    ```yaml
    enabled_generic_second_factors:
        biometric:
            loa: 3
        tiqr:
            loa: 2
        gauth:
            loa: 2
    ```
 
### Stepup-Gateway

1. Add the new GSSP to: `Stepup-Gateway/app/config/parameters.yml`. Example value for the `enabled_generic_second_factors`:

    ```yaml
    enabled_generic_second_factors:
        biometric:
            loa: 3
        tiqr:
            loa: 2
        gauth:
            loa: 2
    ```
2. Add the new GSSP to: `Stepup-Gateway/app/config/samlstepupproviders.yml`

    ``` yaml
    imports:
    
        - { resource: samlstepupproviders_parameters.yml }
    
    surfnet_stepup_gateway_saml_stepup_provider:
        allowed_sps: %gssp_allowed_sps%
        routes:
            sso: gssp_verify
            consume_assertion: gssp_consume_assertion
            metadata: gssp_saml_metadata
        providers:
            tiqr:
                enabled: true
                hosted:
                    service_provider:
                        public_key: %gssp_tiqr_sp_publickey%
                        private_key: %gssp_tiqr_sp_privatekey%
                    identity_provider:
                        service_provider_repository: saml.entity_repository
                        public_key: %gssp_tiqr_idp_publickey%
                        private_key: %gssp_tiqr_idp_privatekey%
                    metadata:
                        public_key: %gssp_tiqr_metadata_publickey%
                        private_key: %gssp_tiqr_metadata_privatekey%
                remote:
                    entity_id: %gssp_tiqr_remote_entity_id%
                    sso_url: %gssp_tiqr_remote_sso_url%
                    certificate: %gssp_tiqr_remote_certificate%
	...
	...
            gauth:
                enabled: true
                hosted:
                    service_provider:
                        public_key: %gssp_gauth_sp_publickey%
                        private_key: %gssp_gauth_sp_privatekey%
                    identity_provider:
                        service_provider_repository: saml.entity_repository
                        public_key: %gssp_gauth_idp_publickey%
                        private_key: %gssp_gauth_idp_privatekey%
                    metadata:
                        public_key: %gssp_gauth_metadata_publickey%
                        private_key: %gssp_gauth_metadata_privatekey%
                remote:
                    entity_id: %gssp_gauth_remote_entity_id%
                    sso_url: %gssp_gauth_remote_sso_url%
                    certificate: %gssp_gauth_remote_certificate%
                    
    ```

3. And add the parameters to `Stepup-Gateway/app/config/samlstepupproviders_parameters.yml`:

    ```yaml
    parameters:
        # A list of service provider entity IDs that are allowed to send authn requests to the GSSPs
        # the routes should be kept as is, they map to specific URLs on the gateway
        gssp_routes_sso: gssp_verify
        gssp_routes_consume_assertion: gssp_consume_assertion
        gssp_routes_metadata: gssp_saml_metadata
    
        # A list of service provider entity IDs that are allowed to send AuthnRequests to the GSSPs
        # Update domain name to match the domain name of the SS and RA.
        gssp_allowed_sps:
            - 'https://selfservice.tld/registration/gssf/tiqr/metadata'
            - 'https://ra.tld/vetting-procedure/gssf/tiqr/metadata'
    
    
        # Configuration of the "tiqr" GSSP
        # Authentication flow:
        # Real Tiqr GSSP IdP <--> Gateway GSSP Tiqr SP <--> Gateway GSSP Tiqr IdP Proxy <--> RA | SS
        # AuthnRequests from the RA and SS are proxied through the Tiqr GSSP proxy on the Gateway
        # The GSSP Tiqr SP and IdP are hosted on the gateway
        
        # Tiqr SP Proxy for authenticating with the real (i.e. external) tiqr IdP
        gssp_tiqr_sp_publickey: '/full/path/to/the/gateway-as-sp/public-key-file.cer'
        gssp_tiqr_sp_privatekey: '/full/path/to/the/gateway-as-sp/private-key-file.pem'
    
        # Certificate and private key of Tiqr SAML IdP Proxy for use by RA and SS
        gssp_tiqr_idp_publickey: '/full/path/to/the/gateway-as-idp/public-key-file.cer'
        gssp_tiqr_idp_privatekey: '/full/path/to/the/gateway-as-sp/private-key-file.pem'
    
        # Metadata signing cert and key for tiqr SP/IdP proxy
        gssp_tiqr_metadata_publickey: '/full/path/to/the/gateway-metadata/public-key-file.cer'
        gssp_tiqr_metadata_privatekey: '/full/path/to/the/gateway-as-sp/private-key-file.pem'
    
        # Real (i.e. external) Tiqr GSSP IdP
        gssp_tiqr_remote_entity_id: 'https://tiqr.tld/saml/metadata'
        gssp_tiqr_remote_sso_url: 'https://tiqr.tld//saml/sso'
        gssp_tiqr_remote_certificate: 'The contents of the certificate published by the gssp, excluding PEM headers'
	...
	...       
        # Configuration of the "gauth" GSSP
        gssp_gauth_sp_publickey: '/full/path/to/the/gateway-as-sp/public-key-file.cer'
        gssp_gauth_sp_privatekey: '/full/path/to/the/gateway-as-sp/private-key-file.pem'        
        gssp_gauth_idp_publickey: '/full/path/to/the/gateway-as-idp/public-key-file.cer'
        gssp_gauth_idp_privatekey: '/full/path/to/the/gateway-as-sp/private-key-file.pem'
        gssp_gauth_metadata_publickey: '/full/path/to/the/gateway-metadata/public-key-file.cer'
        gssp_gauth_metadata_privatekey: '/full/path/to/the/gateway-as-sp/private-key-file.pem'    
        gssp_gauth_remote_entity_id: 'https://gauth.tld/saml/metadata'
        gssp_gauth_remote_sso_url: 'https://gauth.tld//saml/sso'
        gssp_gauth_remote_certificate: 'The contents of the certificate published by the gssp,
    ```

### Stepup-SelfService

1.  Add the new GSSP to: `Stepup-SelfService/app/config/parameters.yml`. Example value for the `enabled_generic_second_factors`:

    ```yaml
    enabled_generic_second_factors:
        biometric:
            loa: 3
        tiqr:
            loa: 2
        gauth:
            loa: 2
    ```
 2. Add the new GSSP to `providers` found in `Stepup-SelfService/app/config/samlstepupproviders.yml`. Example:

    ```yaml
    gauth:
        hosted:
            service_provider:
                public_key: %gssp_gauth_sp_publickey%
                private_key: %gssp_gauth_sp_privatekey%
            metadata:
                public_key: %gssp_gauth_metadata_publickey%
                private_key: %gssp_gauth_metadata_privatekey%
        remote:
            entity_id: %gssp_gauth_remote_entity_id%
            sso_url: %gssp_gauth_remote_sso_url%
            certificate: %gssp_gauth_remote_certificate%
        view_config:
            loa: %gssp_gauth_loa%
            logo: %gssp_gauth_logo%
            alt: %gssp_gauth_alt%
            title: %gssp_gauth_title%
            description: %gssp_gauth_description%
            button_use: %gssp_gauth_button_use%
            initiate_title: %gssp_gauth_initiate_title%
            initiate_button: %gssp_gauth_initiate_button%
            explanation: %gssp_gauth_initiate_title%
            authn_failed: %gssp_gauth_authn_failed%
            pop_failed: %gssp_gauth_pop_failed%
    ```
3. Add the newly added parameters to `Stepup-SelfService/app/config/samlstepupproviders_parameters.yml`. Note that 
translations are specified in the parameters.

    ```yaml
    gssp_gauth_sp_publickey: '%kernel.root_dir%/../vendor/surfnet/stepup-saml-bundle/src/Resources/keys/development_publickey.cer'
    gssp_gauth_sp_privatekey: '%kernel.root_dir%/../vendor/surfnet/stepup-saml-bundle/src/Resources/keys/development_privatekey.pem'
    gssp_gauth_metadata_publickey: '%kernel.root_dir%/../vendor/surfnet/stepup-saml-bundle/src/Resources/keys/development_publickey.cer'
    gssp_gauth_metadata_privatekey: '%kernel.root_dir%/../vendor/surfnet/stepup-saml-bundle/src/Resources/keys/development_privatekey.pem'
    gssp_gauth_remote_certificate: 'The contents of the certificate published by the gssp'
    gssp_gauth_remote_entity_id: 'https://gw-dev.stepup.coin.surf.net/app_dev.php/gssp/gauth/metadata'
    gssp_gauth_remote_sso_url: 'https://gw-dev.stepup.coin.surf.net/app_dev.php/gssp/gauth/single-sign-on'
    gssp_gauth_loa: 2
    gssp_gauth_logo: /images/second-factor/gauth.png
    gssp_gauth_alt:
        en_GB: 'Gauth device'
        nl_NL: 'Gauth apparaat'
    gssp_gauth_title:
        en_GB: 'Gauth device'
        nl_NL: 'Gauth apparaat'
    gssp_gauth_description:
        en_GB: 'Log in using a Gauth device.'
        nl_NL: 'Log in met een gauth apparaat.'
    gssp_gauth_button_use:
        en_GB: Select
        nl_NL: Selecteer
    gssp_gauth_initiate_title:
        en_GB: 'Register a Gauth device'
        nl_NL: 'Registratie gauth apparaat'
    gssp_gauth_initiate_button:
        en_GB: 'Register Gauth device'
        nl_NL: 'Registreer gauth apparaat'
    gssp_gauth_explanation:
        en_GB: 'Click the button below to register a Gauth device.'
        nl_NL: 'Klik op de knop hieronder om je gauth apparaat te registreren.'
    gssp_gauth_authn_failed:
        en_GB: 'Registration of Gauth device has failed. Please try again.'
        nl_NL: 'Registratie gauth apparaat is mislukt. Probeer het nogmaals.'
    gssp_gauth_pop_failed:
        en_GB: 'Registration of your token failed. Please try again.'
        nl_NL: 'De registratie van uw token is mislukt. Probeer het nogmaals.'
    ```

### Stepup-RA

1.  Add the new gssf to: `Stepup-RA/app/config/parameters.yml`. Example value for the `enabled_generic_second_factors`:

    ```yaml
    enabled_generic_second_factors:
        biometric:
            loa: 3
        tiqr:
            loa: 2
        gauth:
            loa: 2
    ```
2. Add the new gssf to `providers` found in `Stepup-RA/app/config/samlstepupproviders.yml`. Example:

    ```yaml
    gauth:
        hosted:
            service_provider:
                public_key: %gssp_gauth_sp_publickey%
                private_key: %gssp_gauth_sp_privatekey%
            metadata:
                public_key: %gssp_gauth_metadata_publickey%
                private_key: %gssp_gauth_metadata_privatekey%
        remote:
            entity_id: %gssp_gauth_remote_entity_id%
            sso_url: %gssp_gauth_remote_sso_url%
            certificate: %gssp_gauth_remote_certificate%
        view_config:
            page_title: %gssp_gauth_page_title%
            explanation: %gssp_gauth_explanation%
            initiate: %gssp_gauth_initiate%
            gssf_id_mismatch: %gssp_gauth_gssf_id_mismatch% 
    ```
3. Add the newly added parameters to `Stepup-RA/app/config/samlstepupproviders_parameters.yml`. Note that 
translations are specified in the parameters.

    ```yaml
     gssp_gauth_sp_publickey: /full/path/to/the/gateway-as-sp/public-key-file.cer
     gssp_gauth_sp_privatekey: /full/path/to/the/gateway-as-sp/private-key-file.pem
     gssp_gauth_metadata_publickey: /full/path/to/the/gateway-metadata/public-key-file.cer
     gssp_gauth_metadata_privatekey: /full/path/to/the/gateway-as-sp/private-key-file.pem
     gssp_gauth_remote_entity_id: 'https://actual-gssp.entity-id.tld'
     gssp_gauth_remote_sso_url: 'https://actual-gssp.entity-id.tld/single-sign-on/url'
     gssp_gauth_remote_certificate: 'The contents of the certificate published by the gssp'
     gssp_gauth_page_title:
         en_GB: 'EN ra.vetting.gssf.initiate.gauth.title.page'
         nl_NL: 'NL ra.vetting.gssf.initiate.gauth.title.page'
     gssp_gauth_explanation:
         en_GB: 'EN ra.vetting.gssf.initiate.gauth.text.explanation'
         nl_NL: 'NL ra.vetting.gssf.initiate.gauth.text.explanation'
     gssp_gauth_initiate:
         en_GB: 'EN ra.vetting.gssf.initiate.gauth.button.initiate'
         nl_NL: 'NL ra.vetting.gssf.initiate.gauth.button.initiate'
     gssp_gauth_gssf_id_mismatch:
         en_GB: 'EN ra.vetting.gssf.initiate.gauth.error.gssf_id_mismatch'
         nl_NL: 'NL ra.vetting.gssf.initiate.gauth.error.gssf_id_mismatch'
    ```