These are the Ansible playbooks and scripts to create the step-up infrastructure and to deploy stepup components (i.e. stepup-middleware, stepup-gateway, stepup-ra, stepup-selfserve, stepup-tiq and oath-server-php) to this infra. The playbooks are targeted to a CentOS 7 image and should be usable with any environment (i.e. not be specific to a test or a production environment).

The Ansible playbooks and the deploy script require an "environment". An "enviroment" is the part of the playbook that contains the configuration (e.g. passwords, certificates, urls, email addresses, hostnames, ...) of the infrastructure that is being targeted. A template environment is provided in "environments/template". This template can be used as a starting point for creating a new environment. When using ansible playbook the environment to use is selected by specifying the ``inventory`` file of the environment using the ``-i`` option.

Creating a new Environment
--------------------------

Using the `create_new_environment.sh` script a new environment can be created based on the template. The new environment does not have to (and typically shouldn't) be stored in this repository. The intended use is to store the environment in a different, private, repository. The secrets (private keys, password etc) in the environment are encrypted in a vault with a symmetic key using [keyczar]. This keycsar key can be stored in a safe location (e.g. on a deploy host), separate from the environment. The vault differs from the standard ansble vault. The vault setup is described in de [Vault](#vault) section below.

Use `create_new_environment.sh <environment_directory>` to create a new environment. This new environment can be used as-is to deploy to VMs created with the scripts in `Stepup-VM`. The script will generate passwords, secrets, SAML signing certificates and SSL server certificates for the environemnt and encrypt these with a keycsar key specific for the environment. For any other environment than one that targets the Stepup-VM you will need to make changes to the new environment. Because the Step-up software depends on external systems additional configuration and setup is required to be able to actually use a Step-up environment. In the new environment:

* Set hostnames, domains, email addresses
* Use proper SSL Server certificates
* Configure API keys for messagebird, yubikey
* Configure remote "first factor" IdP
* Adjust firewall rules
* Move the keycsar key out of the environment

[Create / update infrastructure](id:site)
------------------------------

The deploy process is split in two parts

1. The "infrastructure part". This installs all rpms, configures services, databases, firewalls, loadbalancers etc. 
2. The component part (see [Deploy](#deploy)). This installs and configures the applications ("components"): stepup-gateway, stepup-middleware, stepup-selfservice, stepup-ra, steup-tiqr and oath-server-php.

The deploy requires an environment created with e.g. the `create_new_environment.sh` script.

Use `ansible-playbook -i <environment_directory>/inventory site.yml` to deploy the infrastructure.

The databases form a galera cluster. When none of the MariaDB databases is running, such as during the first deploy, the first database must be bootstrapped by setting the Ansible variable `galera_bootstrap_node` to the hostname of the node to bootstrap. Example:

`ansible-playbook site.yml -i <environment_directory>/inventory -e "galera_bootstrap_node=app.stepup.example.com"`


[Vault](id:vault)
-----

The playbooks use a vault setup that is similar to what is used by SURFconext (SURFconext-deploy). This is different from the way a vault is used normally in Ansible. Instead of encrypting the entire vars file, the individual values are encrypted. The template environemnt is setup to read the encrypted values from files on disk.

For Step-up / SURFconext a keystore is created using keyczar (http://keyczar.org) that contains the key that is used to encrypt / decrypt the secrets that are used in the playbook. The secrets are encrypted individually and the resulting base64 encoded values are stored in the environment. This provides a more git friendly playbook.

A custom ansible filter plugin "vault" (see `filter_plugins/custom_plugins.py`) is used to decrypt values using the key from the keystore. E.g: `{{ encrypted_value | vault(vault_keydir) }}`. This decryption is done on the host from which ansible-playbook is run.

* `encrypted_value` is an Ansible variable that contains the encrypted value.
* `vault_keydir` is an Ansible variable containing the directory where the keyczar vault is stored (e.g. `~/.stepup-ansible-keystore`). The specified directory must be on the host from which ansible-playbook is run.

The stepup playbooks set the location of the ansible vault (`vault_keydir`) in the inventory directory in `group_vars/all.yml`.


To create enrypted values for use in the playbook two scrips are provided:

* For values: `scripts/encrypt.sh <keycsar vault directory>`

* For files: `scripts/encrypt-file.sh <keycsar vault directory> -f <filename>`

These scripts output the encrypted values that can then be stored in de playbook. To decrypt a value manually add the `--decrypt` (or `-d`) option.

You need python-keyczar installed. Install with e.g.:
`pip install python-keyczar==0.71c`


Creating a keystore is done once per environment. After that the keystore is shared between the dev-ops requiring access to a environment. The `create_new_environment.sh` will create a new keystore and encrypt secrets using the keystore. To creating a new keystore manually:

1. Create a directory for the keystore:

   `mkdir ~/.stepup-ansible-keystore`

2. Create a an empty keyset named "stepup" (the key can have any name):

   `keyczart create --location=$HOME/.stepup-ansible-keystore --purpose=crypt --name=stepup`

3. Add a new key to the keyset, and make this the active key

   `keyczart addkey --location=$HOME/.stepup-ansible-keystore --status=primary`


[Build](id:build)
-----

Before a component can be deployed it must be built. This creates a tarball (bar.bz2) that can then be unpacked by the deploy playbook on the application servers. The script to do that is in the [Stepup-Build](https://github.com/SURFnet/Stepup-Build) repository. This script will checkout a component from git on the host, but run composer and create the gzipped tarball to be deployed in a Vagrant VM.

Prebuild components can be downloaded from the release page of the component on GitHub. Make sure to get the prebuild component tar.bz2, and not the source tarball that is automatciaaly created by GitHub. The name of the component has the form `<component-name>-<tag of branch>-<timestamp of last commit>-<commit SHA1>.tar.bz2`. For example:
`Stepup-RA-1.0.2-20150623082722Z-2c4b6389cdbb015ddd470a19f1c04a9feb429032.tar.bz2`

[Deploy](id:deploy)
------

The deploy playbook deploys a component that was build using [Stepup-Build](https://github.com/SURFnet/Stepup-Build). Deploying a component requires the infrastructure to be setup first using [``site.yml``](#site). The deploy playbook is `deploy.yml`. A script is provided to use this playbook to deploy a single component. This script will override the component names in the `deploy.yml` playbook. Usage:

   `scripts/deploy.sh <filename of component tarball> -i <inventory> [-t <tags>] [-l <hosts>] [-v]`

The -i, -t (tags) -l (limit) and -v (verbose) options are passed to `ansible-playbook`

To deploy all components in the ``deploy.yml`` playbook call the playbook and provide the path to the component tarball. I.e. `ansible-playbook deploy.yml -i <inventory> -e tarball_location=<path to tarball directory>'`

Getting started
---------------

* You need a recent Ansible version installed (1.9). The bash scripts and playbooks should run on both OSX and linux (bash). For building the
  stepup components yourself you need Vagrant and a provider like OpenBox or VMWare Fusion otherwise these can be downloaded from gitHub.
* Create an directory in a location of your choice
  `mkdir Stepup`
* Clone Stepup-Deploy repo
  `git clone git@github.com:SURFnet/Stepup-Deploy.git`
* Make sure you have the environment, the keystore for the environment and the ssh config, if not ask...
    * Put the keystore in the directory that is set for the `vault_keydir` variable.
    * Configure the ssh properties for the hosts in your ~/.ssh/config
  To create a new environment:
    `Stepup-Deploy/scripts/create_new_environment.sh new_environment`

The [Stepup-VM](https://github.com/SURFnet/Stepup-VM) repository contains a vagrant configuration that can be used to create a VM suitable for testing the deploy of a Step-up environment that was created using the `create_new_environment.sh` script.

* Clone the Stepup-VM repo and start the VMs, see Stepup-VM for details (requires Vagrant and a provider like VirtualBox)
  `git clone git@github.com:SURFnet/Stepup-VM.git`
  `cd Stepup-VM`
  `vagrant up`

* Deploy the infrastructure to the VMs:
  ```ansible-playbook site.yml -i <your environment>/inventory```
  
* Deploy the components to the VMs:
  ```ansible-playbook deploy.yml -i <inventory> -e tarball_location=<path to tarball directory>```
  

### Example ###

To build and deploy a new version of the selfservice component to the existing test environment you would run:

1. `.../Stepup-Build/stepup-build.sh Stepup-SelfService`
   This creates a tarball (e.g. `Stepup-SelfService-develop-20150223143536Z-6ef51b629bc968218b582605894445b857927a4d.tar.bz2`) in the current directory
2. `.../Stepup-Deploy/scripts/deploy.sh Stepup-SelfService-develop-20150223143536Z-6ef51b629bc968218b582605894445b857927a4d.tar.bz2 -l "app*" -i <some environment>/inventory`
   This deploys the tarball to the hosts in the referenced inventory with a name starting with "app".
   
[keyczar]: http://www.keyczar.org "www.keyczar.org"

