This are the Ansible playbooks to create the step-up infrastructure on the OpenStack utrecht.surfcloud.nl and to deploy stepup components (i.e. middleware, gateway, RA, selfserve) to this infra. The playbook is targeted to the CentOS 6.5 image.

Create / update infrastructure
------------------------------

Use `ansible-playbook site.yml`

Optional `--tags`:

* common
* db
* app

The databases form a galera cluster. When none of the MariaDB databases is running the first database must be bootstrapped by setting galera_bootstrap_node to the hostname of the node to bootstrap. Example: 

`ansible-playbook site.yml -e "galera_bootstrap_node=app1.suaas.utr.surfcloud.nl"`


Vault
-----

The playbooks use the same vault setup as is used by SURFconext (SURFconext-deploy). This differs from the way a vault is used normally in Ansible. 

Using keyczar (http://keyczar.org) a keystore is created that contains the key that is used to encrypt / decrypt the secrets that are used in the playbook. The secrets are encrypted individually and the resulting base64 encoded values are stored in the playbook. This provides a more git friendly playbook.

A ansible filer plugin "vault" (`filter_plugins/custom_plugins.py`) is used to decrypt values using the key from the keystore. E.g: `{{ encrypted_value | vault }}`. This decryption is done on the host from which ansible-playbook is run. 

The stepup-ansible-keystore is stored in `~/.stepup-ansible-keystore`. It must not be stored in the cloud (github, dropbox, etc). The filter references the keystore in `~/.stepup-ansible-keystore`. 

To create enrypted values for use in thr playbook use:

* For values: `scripts/encrypt.sh`

* For files: `scripts/encrypt-file.sh`

To decrypt a value manually add the "--decrypt" option.

You need python-keyczar. Install with e.g.:
`pip install python-keyczar==0.71c`


Creating a keystore is done once per environment. After that the keystore is shared between the dev-ops requiring access to a environment. Creating a new keystore:

1. Create directory

   `mkdir ~/.stepup-ansible-keystore`
   
2. Create a an empty keyset named "stepup-dev": 
   
   `keyczart create --location=$HOME/.stepup-ansible-keystore --purpose=crypt --name=stepup-dev`

3. Add a new key to the keyset, and make this the active key

   `keyczart addkey --location=$HOME/.stepup-ansible-keystore --status=primary`


Deploy
------

Very much a WIP still. The deploy playbook is `deploy.yml`. Usage:

    `ansible-playbook deploy.yml` 

to Deploy a single component to a single server:
    `ansible-playbook deploy.yml --tags gateway --limit "app1*"` 


Build
-----

Before a component can be deployed it must be built. This creates a tarball that can then be unpacked by the deploy playbook on the application servers. The script to do that is `scripts/stepup-build.sh`. This script will checkout a comonent from git, run composer and create a tar. The name of the tar to deploy for each component is set the `deploy.yml` playbook.

