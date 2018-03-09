# Adding new Gssp to Stepup
This document shows the steps to register a new generic second factor to the Stepup project. This is text was written 
during testing of the addition of the feature. The actual implementation is not described in this document.
 
Middleware
---
1. Add the new gssf to: `Stepup-Middleware/app/config/parameters.yml`. Example value for the `enabled_generic_second_factors`:
    ```yaml
    enabled_generic_second_factors:
        biometric:
            loa: 3
        tiqr:
            loa: 3
        gauth:
            loa: 2
    ```
 
Gateway
---
1.  Add the new gssf to: `Stepup-Gateway/app/config/parameters.yml`. Example value for the `enabled_generic_second_factors`:
    ```yaml
    enabled_generic_second_factors:
        biometric:
            loa: 3
        tiqr:
            loa: 3
        gauth:
            loa: 2
    ```

SelfService
---
1.  Add the new gssf to: `Stepup-SelfService/app/config/parameters.yml`. Example value for the `enabled_generic_second_factors`:
    ```yaml
    enabled_generic_second_factors:
        biometric:
            loa: 3
        tiqr:
            loa: 3
        gauth:
            loa: 2
    ```
 2. Add the new gssf to `providers` found in `Stepup-SelfService/app/config/samlstepupproviders.yml`. Example:
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

## Configuring app url's for profiders
Set the Android and/or iOs URL in `samlstepupprovidres.yml` like this:

```yaml
surfnet_stepup_self_service_saml_stepup_provider:
    routes:
	...
    providers:
        tiqr:
            hosted:
                ...
            remote:
                ...
            view_config:
                ...
                description: %gssp_tiqr_description%                
                app_android_url: %gssp_tiqr_app_android_url%
                app_ios_url: %gssp_tiqr_app_ios_url%
		...
        miko:
            hosted:
                ...
            remote:
                ...
            view_config:
                ...
                description: %gssp_miko_description%                
                app_android_url: %gssp_miko_app_android_url%
		...
```

Note that the app url's are optional config settings. 

When adding one of the two supported app url's the description must be set accordingly. The `samlstepupproviders_parameters.yml` file for the explanation above:

```yaml
gssp_tiqr_description:
parameters:
    gssp_tiqr_description:
        en_GB: 'Log in with a smartphone app. For all smartphones with %%ios_link_start%%Apple iOS%%ios_link_end%% or %%android_link_start%%Android%%android_link_end%%.'
        nl_NL: 'Log in met een app op je smartphone. Geschikt voor smartphones met %%ios_link_start%%Apple iOS%%ios_link_end%% of %%android_link_start%%Android%%android_link_end%%.'
gssp_miko_description:
        en_GB: 'Log in with a Miko smartphone app. For all smartphones with %%android_link_start%%Android%%android_link_end%%.'
        nl_NL: 'Log in met een Miko app op je smartphone. Geschikt voor smartphones met %%android_link_start%%Android%%android_link_end%%.'
    
```

The application wil validate the descriptions for the correct app url tokens.

RA
---
1.  Add the new gssp to: `Stepup-RA/app/config/parameters.yml`. Example value for the `enabled_generic_second_factors`:
    ```yaml
    enabled_generic_second_factors:
        biometric:
            loa: 3
        tiqr:
            loa: 3
        gauth:
            loa: 2
    ```
2. Add the new gssp to `providers` found in `Stepup-RA/app/config/samlstepupproviders.yml`. Example:
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
     gssp_gauth_name:
          en_GB: 'EN the English name for the provider'
          nl_NL: 'NL the Dutch name for the provider'
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