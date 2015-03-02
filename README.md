These are the Ansible playbooks to create the step-up infrastructure and to deploy stepup components (i.e. middleware, gateway, RA, selfserve) to this infra. The playbooks are targeted to the CentOS 6.5 image.

Create / update infrastructure
------------------------------

Use `ansible-playbook -i <inventory> site.yml`

For `<inventory>` specify one of the inventories in environments. E.g. `environments/test/inventory`

The databases form a galera cluster. When none of the MariaDB databases is running the first database must be bootstrapped by setting the Ansible varibale `galera_bootstrap_node` to the hostname of the node to bootstrap. Example:

`ansible-playbook site.yml -i "environments/test/inventory" -e "galera_bootstrap_node=app1.suaas.utr.surfcloud.nl"`


Vault
-----

The playbooks use a vault setup that is similar to what is used by SURFconext (SURFconext-deploy). This is different from the way a vault is used normally in Ansible.

For Step-up / SURFconext a keystore is created using keyczar (http://keyczar.org) that contains the key that is used to encrypt / decrypt the secrets that are used in the playbook. The secrets are encrypted individually and the resulting base64 encoded values are stored in the inventory. This provides a more git friendly playbook.

A custom ansible filter plugin "vault" (see `filter_plugins/custom_plugins.py`) is used to decrypt values using the key from the keystore. E.g: `{{ encrypted_value | vault(vault_keydir) }}`. This decryption is done on the host from which ansible-playbook is run.

* `encrypted_value` is an Ansible variable that contains the encrypted value.
* `vault_keydir` is an Ansible variable containing the directory where the keyczar vault is stored (e.g. `~/.stepup-ansible-keystore`). The specified directory must be on the host from which ansible-playbook is run.

The stepup playbooks set the location of the ansible vault (`vault_keydir`) in the inventory directory in `group_vars/all.yml`.


To create enrypted values for use in the playbook two scrips are provided:

* For values: `scripts/encrypt.sh <keycsar vault directory>`

* For files: `scripts/encrypt-file.sh <keycsar vault directory> -f <filename>`

These scripts output the encrypted values that can then be stored in de playbook. To decrypt a value manually add the `--decrypt` option.

You need python-keyczar. Install with e.g.:
`pip install python-keyczar==0.71c`


Creating a keystore is done once per environment. After that the keystore is shared between the dev-ops requiring access to a environment. Creating a new keystore:

1. Create a directory for the keystore:

   `mkdir ~/.stepup-ansible-keystore`

2. Create a an empty keyset named "stepup-dev" (the key can have any name):

   `keyczart create --location=$HOME/.stepup-ansible-keystore --purpose=crypt --name=stepup-dev`

3. Add a new key to the keyset, and make this the active key

   `keyczart addkey --location=$HOME/.stepup-ansible-keystore --status=primary`


Build
-----

Before a component can be deployed it must be built. This creates a tarball that can then be unpacked by the deploy playbook on the application servers. The script to do that is in the [Stepup-Build](https://github.com/SURFnet/Stepup-Build) repository. This script will checkout a component from git on the host, but run composer and create a gzipped tarball to be deployed in a Vagrant VM.

Alternatively the deprecated `scripts/stepup-build.sh` script in this repo can be used. This script performs all actions on the host, thus requires php, composer etc on the host.


Deploy
------

Still WIP. The depoy playbook deploys a component that was build using [Stepup-Build](https://github.com/SURFnet/Stepup-Build. The deploy playbook is `deploy.yml`. A script is provided to use this playbook to deploy a component. Usage:

   `scripts/deploy.sh <filename of component tarball> -i <inventory> [-t <tags>] [-l <hosts>] [-v]`

The -i, -t (tags) -l (limit) and -v (verbose) options are passed to ansible-playbook


Getting started
---------------

* You need PHP (5.4), and a somewhat resent Ansible installed (e.g. 1.7). Scripts and playbooks should run on both OSX and linux
* Make sure you have the keystore for the environment and the ssh config, if not ask...
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
2. `.../Stepup-Deploy/scripts/deploy.sh Stepup-SelfService-develop-20150223143536Z-6ef51b629bc968218b582605894445b857927a4d.tar.bz2 -l "app1*" -i .../Stepup-Deploy/environments/test/inventory`
   This deploys the tarball the hosts with name starting with "app1".


