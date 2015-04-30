These are the Ansible playbooks to create the step-up infrastructure and to deploy stepup components (i.e. middleware, gateway, RA, selfserve) to this infra. The playbooks are targeted to a CentOS 7 image.

Creating a new Environment
--------------------------

The playbooks and the deploy script require a "environment" that contains the configuration (e.g. passwords, certificates, urls, email addresses, hostnames, ...) of the infrastructure that is being targeted. A template environment is provided in "environments/template". This template can be used as a starting point for a new environment. Using the `create_new_environment.sh` script a new environment can be created. The new environment does not have to (and typically shouldn't) be stored in this repository. The intended use is to store the environment in a different, private, repository. Secrets (private keys, password etc) are encrypted with a smmetic key. This key kan be stored in a safe location (e.g. on a deploy host), sepearate from the environment.

Use `create_new_environment.sh <environment_directory>` to create a new environment. The created environment can be used to deploy to VMs created with the scripts in `Stepup-VM`.

Create / update infrastructure
------------------------------

The requires an environment created with e.g. the `create_new_environment.sh` script.

Use `ansible-playbook -i <environment_directory>/inventory site.yml`

The databases form a galera cluster. When none of the MariaDB databases is running the first database must be bootstrapped by setting the Ansible varibale `galera_bootstrap_node` to the hostname of the node to bootstrap. Example:

`ansible-playbook site.yml -i <environment_directory>/inventory -e "galera_bootstrap_node=app.stepup.example.com"`


Vault
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

These scripts output the encrypted values that can then be stored in de playbook. To decrypt a value manually add the `--decrypt` option.

You need python-keyczar installed. Install with e.g.:
`pip install python-keyczar==0.71c`


Creating a keystore is done once per environment. After that the keystore is shared between the dev-ops requiring access to a environment. The `create_new_environment.sh` will create a new keystore and encrypt secrets using the keystore. To creating a new keystore manually:

1. Create a directory for the keystore:

   `mkdir ~/.stepup-ansible-keystore`

2. Create a an empty keyset named "stepup" (the key can have any name):

   `keyczart create --location=$HOME/.stepup-ansible-keystore --purpose=crypt --name=stepup`

3. Add a new key to the keyset, and make this the active key

   `keyczart addkey --location=$HOME/.stepup-ansible-keystore --status=primary`


Build
-----

Before a component can be deployed it must be built. This creates a tarball that can then be unpacked by the deploy playbook on the application servers. The script to do that is in the [Stepup-Build](https://github.com/SURFnet/Stepup-Build) repository. This script will checkout a component from git on the host, but run composer and create the gzipped tarball to be deployed in a Vagrant VM.

Alternatively the deprecated `scripts/stepup-build.sh` script in this repo can be used. This script performs all actions on the host, thus requires php, composer etc on the host.


Deploy
------

The depoy playbook deploys a component that was build using [Stepup-Build](https://github.com/SURFnet/Stepup-Build). The deploy playbook is `deploy.yml`. A script is provided to use this playbook to deploy a component. Usage:

   `scripts/deploy.sh <filename of component tarball> -i <inventory> [-t <tags>] [-l <hosts>] [-v]`

The -i, -t (tags) -l (limit) and -v (verbose) options are passed to ansible-playbook


Getting started
---------------

* You a resent Ansible installed (1.9). The bash scripts and playbooks should run on both OSX and linux
* Make sure you have the environment, the keystore for the environment and the ssh config, if not ask...
	* Put the keystore in the directory that is set for the `vault_keydir` variable.
	* Configure the ssh properties for the hosts in your ~/.ssh/config
* Create an directory in a location of your choice
* Clone Stepup-Deploy repo
  `git clone git@github.com:SURFnet/Stepup-Deploy.git`
* Clone Stepup-Build repo, follow instructions in that repo for creating the build machine.
  `git clone git@github.com:SURFnet/Stepup-Build.git`

### Example ###

To build and deploy a new version of the selfservice component to the existing test environment you would run:

1. `.../Stepup-Build/stepup-build.sh Stepup-SelfService`
   This creates a tarball (e.g. `Stepup-SelfService-develop-20150223143536Z-6ef51b629bc968218b582605894445b857927a4d.tar.bz2`) in the current directory
2. `.../Stepup-Deploy/scripts/deploy.sh Stepup-SelfService-develop-20150223143536Z-6ef51b629bc968218b582605894445b857927a4d.tar.bz2 -l "app*" -i <some environment>/inventory`
   This deploys the tarball the hosts in the referenced inventory with a name starting with "app".
