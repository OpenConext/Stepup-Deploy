Ansible deploy scripts for Stepup Infrastructure
================================================

These are the Ansible playbooks and scripts to create, deploy and manage a step-up infrastructure and to deploy the stepup components (i.e. stepup-middleware, stepup-gateway, stepup-ra, stepup-selfservice, stepup-tiqr and oath-server-php) to this infrastructure. The playbooks are targeted to a CentOS 7 image and should be usable with any environment (i.e. not be specific to a test or a production environment).

The Ansible playbooks and the deploy script require an "environment". An "environment" is the part of the playbook that contains the configuration (e.g. passwords, certificates, urls, email addresses, hostnames, ...) of the infrastructure that is being targeted. A template environment is provided in "environments/template". This template can be used as a starting point for creating your new environment. When using ansible playbook the environment to use is selected by specifying the ``inventory`` file of the environment using the ``-i`` option.


What is Stepup?
---------------

Stepup authentication as-a-service, or Stepup for short, is an open source project that was started by [SURFnet](http://surfnet.nl) to create what is now called "SURF SecureID" (and "SURFconext Strong Authentication" before that). It works seamlessly with [OpenConext](http://openconext.org) to add Step-up authentication for (SAML) Service Providers. The Stepup system manages authentication _and_ registration of the second factors without requiring technical integration with the identity provider, which is great if you need to support many different identity providers. For SAML service providers (SPs) an "always require stepup" policy is available that allows SPs to connect to Stepup with very little to no integration effort. For a more feature rich integration SAML Scoping with RequestedAuthnContext is supported.

Stepup is not limited to be used with OpenConext. There is nothing that precludes it from being used by itself to add Step-up authentication to:

- an existing SAML identity provider
- one or many SAML service providers
- other SAML proxies or hubs

How SURFnet uses Stepup to offer strong authentication to cloud services: https://www.surf.nl/en/knowledge-base/2015/animation-surfconext-strong-authentication.html

More information resources can be found at the [end of the readme](#moreinfo). 

[Deploy process](id:deploy)
---------------------------

Setting up a new Stepup infrastructure consists of 4 steps:

1. [Create an "environment"]((#create-environment)) that contains the configuration of the infrastructure and the stepup applications.
2. [Deploy the Stepup infrastructure](#site). This installs all rpms, configures services, databases, firewalls, loadbalancers etc. 
3. [Deploy the Stepup components](#deploy). This installs the stepup applications ("components") and writes the application configuration: stepup-gateway, stepup-middleware, stepup-selfservice, stepup-ra, steup-tiqr and oath-server-php. 
4. [Post installation configuration](#postinstall). This includes executing the scripts on the application server that initialise or update the database and running the scripts that push the configuration to the database.  

### [Step 1: Creating a new Environment](id:create-environment) ###

Using the [`create_new_environment.sh`](scripts/create_new_environment.sh) script a new environment can be created based on a [template](environments/template/). This new environment does not have to (and typically shouldn't) be stored in this repository. The intended use is to store the environment in a different, private, repository. The secrets (private keys, password etc) in the environment are stored in files that are encrypted with a symmetric key using [python-keyczar](https://pypi.python.org/pypi/python-keyczar). This keyczar key can be stored in a safe location (e.g. on a deploy host), separate from the environment. The standard Ansible vault is not used in this process. The template contains an [`environment.conf`](environments/template/environment.conf) file that specifies the secrets to create.

Requirements for running the script:
- *openssl*
- *python-keyczar*. You can use `pip install python-keyczar` to install this tool. This makes `keyczart` command available.

Use `create_new_environment.sh <environment_directory>` to create a new environment. This new environment can be used as-is to deploy to VMs created with the scripts in [Stepup-VM](https://github.com/SURFnet/Stepup-VM). The script will generate passwords, secrets, SAML signing certificates and SSL/TLS server certificates for use with HTTPS for the environment. All passwords, (private) keys and secrets are encrypted with a keyczar key that is specific for the environment. To issue the server certificates a self-signed CA is created using openssl. The configuration is read from 

For any other environment than one that targets the Stepup-VM you will need to make changes to the new environment. Because the Stepup software depends on external systems, additional configuration and setup is required to be able to actually use a Stepup environment. The locations in the new environment where you may need to make changes to match the requirements of your setup are marked with "TODO". Changes to make include:

* Set hostnames, domains, email addresses
* Replace the SSL Server certificates (for production, the certificates work fine for test in most browsers, but with warnings)
* Configure API keys for messagebird, yubikey
* Configure the remote "first factor" IdP
* Adjust firewall rules (for production)
* Move the keyczar key out of the environment (for production)

More information on the "environment" concept can be found in [ansible-tools](https://github.com/pmeulen/ansible-tools)

### [Step 2: Create / update infrastructure](id:site) ###

The [site.yml](site.yml) playbook handles the configuration of your infrastructure. This playbook requires [Ansible](http://ansible.com) version 2.x and uses the environment created in the previous step. You execute Ansible from a Deploy host (e.g. you laptop) to configure other machines. Please consult the extensive [Ansible documentation](http://docs.ansible.com/ansible/) for [Ansible installation instructions]((http://docs.ansible.com/ansible/intro_installation.html)) and more.

You must adjust the Ansible inventory file that was copied over from the template to match your infrastructure. The default inventory assumes you will use two (virtual) machines for running Stepup. This is a minimum setup. The two machines are:

1. An application server ("app.stepup.example.com"), running an nginx+php-fpm web stack and also the database (mariadb+galera) in the template inventory).
2. A management server ("manage.stepup.example.com" in the template inventory), running ELK for log processing. Although you _must_ configure this server in your inventory to successfully deploy you application server, you can skip actually deploying it and have a functional application server.

The (virtual) machine(s) must be running CentOS 7. It is very unlikely that the playbook will work with another CentOS version or with another Linux distribution. 2 GB memory with 15 GB disk is sufficient to install the app server. 

Configure ssh on you deploy host (i.e. the machine on which you will execute ansible-playbook) such that you can connect to machines listed in your inventory and can become root using sudo. Note that you must specify the IP address of the server in the inventory.

Use `ansible-playbook -i <your_environment_directory>/inventory site.yml -e "galera_bootstrap_node=<app>"` to deploy only the application server. Where you replace _<app>_ with the name of the application server in your inventory. You can use the "-l" option to only deploy the app server. I.e.:  `ansible-playbook -i <your_environment_directory>/inventory site.yml -e "galera_bootstrap_node=<app>" -l <app>`

#### Galera ####

The inventory consists of one database running on the application server. The playbook can setup a Galera cluster running on multiple dedicated machines. In a cluster, when none of the MariaDB databases is running, such as during the first deploy, the first database must be bootstrapped by setting the Ansible variable `galera_bootstrap_node` to the hostname of the node to bootstrap. Example: `ansible-playbook site.yml -i <environment_directory>/inventory -e "galera_bootstrap_node=app.stepup.example.com"`

If you are using the minimal configuration in the inventory from the template, you have one database that is running on the application server. This database is configured as a cluster consisting of one node (you could add more nodes later). In this case the most important difference between a normal mysql/mariaDB and the Galera cluster version is that you ever need to start the database you must use `service mysql bootstrap` instead of `service mysql start`.

### [Step 3: Deploy the Stepup components](id:deploy) ###

Stepup components are the applications that together make up the Stepup service. These are:

* [Stepup-Middleware](https://github.com/OpenConext/Stepup-Middleware). Is used by the Selfservice component and the RA component. The middleware component is the only component that writes to the database. The other components do not communicate with the middleware. The middleware component maintains the middleware and the gateway databases. Updating the configuration of the Stepup system is performed by sending commands to the middleware. 
* [Stepup-Gateway](https://github.com/OpenConext/Stepup-Gateway). The gateway reads its configuration from the gateway database. It is a SAML proxy and handles all authentication request in the Stepup system by interacting with external authentication providers (1st factor SAML IdP, Messagebird SMS gateway, Stepup-tiqr or the Yubico Cloud). SAML Service Provides use this gateway for authentication.
* [Stepup-Selfservice](https://github.com/OpenConext/Stepup-Selfservice). This is the web application where end users register to get stepup token (Yubikey, SMS, tiqr or U2F), can see its status and can revoke their token.
* [Stepup-RA](https://github.com/OpenConext/Stepup-RA). This is the web application where registration authorities (RAs) approve (vet) token registrations.  
* [Stepup-tiqr](https://github.com/OpenConext/Stepup-tiqr). This is the web application that handles tiqr registration and authentications.
* [oath-service-php](https://github.com/SURFnet/oath-service-php). This a server for storing the secrets used by tiqr.

Stepup components are deployed on a machine this is previously prepared as described in the previous steps. The playbook used for deploying the stepup components requires a [prebuild](#build) tarball of the component. Prebuild components can be downloaded from the release page of the component on GitHub.
 
The deploy playbook is [`deploy.yml`](deploy.yml). A [`deploy.sh`](scrips/deply.sh) script is provided to use this ansible-playbook to deploy a single component. This script will override the component names in the `deploy.yml` playbook. Usage:
 
    `scripts/deploy.sh <filename of component tarball> -i <inventory> [-t <tags>] [-l <hosts>] [-v]`
 
The -i, -t (tags) -l (limit) and -v (verbose) options are passed verbatim to `ansible-playbook`
 
optionally, to deploy all components in the `deploy.yml` playbook in one go, you can call the playbook directly and provide the path to where the component tarballs are stored. I.e. `ansible-playbook deploy.yml -i <inventory> -e tarball_location=<path to tarball directory on the deply host>'`

#### [Building Components](id:build) ####

Before a component can be deployed it must be built. This creates a tarball (tar.bz2) that can then be unpacked by the deploy playbook on the application servers. The script to do that is in the [Stepup-Build](https://github.com/OpenConext/Stepup-Build) repository. This script will checkout a component from git on the host, but run composer and create the gzipped tarball to be deployed in a Vagrant VM.

Prebuild components can be downloaded from the release page of the component on GitHub. Make sure to get the prebuild component tar.bz2, and not the source tarball that is automatically created by GitHub. The name of a component has the form `<component-name>-<tag of branch>-<timestamp of last commit>-<git commit SHA1>.tar.bz2`. For example: `Stepup-RA-1.0.2-20150623082722Z-2c4b6389cdbb015ddd470a19f1c04a9feb429032.tar.bz2`


### [Step 4: Post Installation Configuration](id:postinstall) ###

The fourth and last step is to perform post installation configuration. This consists of:
- Creating database schema's for the applications
- Writing the configuration to the database

The databases schemas and users for the Stepup components were created by the db role in [Step 2](#site), but were not further initialised. In [Step 3](#deploy) each component added one or more scripts to the /root/ directory on the machines(s) where it was deployed.  

To perform the post installation configuration you must execute each of these scripts once. Because some scripts are order dependent they are numbered in the order they should be executed. If two scrips have the same number, their order is not important. All the scripts except "06-middleware-bootstrap-sraa-users.sh" are idempotent, meaning they can be called multiple times without ill effect.


[More information](id:moreinfo)
================

CHANGELOG
---------

The [https://github.com/OpenConext/Stepup-Deploy/blob/develop/CHANGELOG](CHANGELOG) in this repo lists the changes of not only the deployment scrips, but also the changes in the stepup components.

[Pivotal Issue tracker](id:pivotal)
---------------------

Much of the development discussions take place outside github in a pivotal tracker: https://www.pivotaltracker.com/n/projects/1163646

Releated github repositories
----------------------------

### Stepup Components ###

These are the main repositories for the Stepup components that can be deployed on the Stepup infrastructure 

* [Stepup-Middleware](https://github.com/OpenConext/Stepup-Middleware)
* [Stepup-Gateway](https://github.com/OpenConext/Stepup-Gateway)
* [Stepup-Selfservice](https://github.com/OpenConext/Stepup-Selfservice)
* [Stepup-RA](https://github.com/OpenConext/Stepup-RA)
* [Stepup-tiqr](https://github.com/OpenConext/Stepup-tiqr)
* [oath-service-php](https://github.com/SURFnet/oath-service-php)

This in turn use many components and bundles that are stored in other repositories.

### Build Server ###

[Stepup-Build](https://github.com/OpenConext/Stepup-Build) is used for building releases of the stepup components. Prebuild components can be downloaded from the release page of the component on github.

### Stepup VM ####

[Stepup-VM](https://github.com/OpenConext/Stepup-VM) contains scripts for setting up a VM for testing/development

Documentation from SURFnet's SURFconext Strong Authentication service
---------------------------------------------------------------------

SURFnet runs an instance of the Stepup software and offers it as a service to its members. To that end it provides documentation aimed at Identity Providers, Service Provides and users of the service in the SURFconext Strong Authenticaton section of the [Get Conexted wiki](https://wiki.surfnet.nl/display/surfconextdev/SURFconext+Strong+Authentication).

Animation introducing SURFconext Strong authentication https://www.surf.nl/en/knowledge-base/2015/animation-surfconext-strong-authentication.html

Other Documentation
-------------------

The first study on the architecture and processes: https://www.surf.nl/en/knowledge-base/2012/report-step-up-authentication-as-a-service.html

Testing
-------

[`docker_test.sh`](tests/docker_test.sh) does a complete [deploy](#deploy) of an application server and a management server in a CentOS 7 docker container. Apart from running automatically through Travis-ci.org, is serves a working example of a complete Stepup deploy.

The tests create a docker container named 'ansible-test' and work with both a local docker and a remote docker-machine. To run the tests:

- `./tests/docker_test.sh app --clean` -- Test the deployment of the database and all the stepup components
- `./tests/docker_test.sh manage --clean` -- Test the deployment of the management server (ELK stack)

The '--clean' option runs the tests in a clean docker container. Omit the flag to rerun the test in an existing container.

Tests must be run from the root of the git repository (i.e. where this file is located).

Use `docker exec -i -t ansible-test /bin/bash` to get a shell in the running container.


Contributing
------------

Contributions are welcome. Please open an Issue or a PR in the relevant github repository. Note that much of the discussion takes place in [Pivotal](#pivotal).
