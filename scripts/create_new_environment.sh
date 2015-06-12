#!/bin/bash

# Creates a new environment that can be used with Ansible playbooks in Stepup-Deploy
# The script can be rerun in an existing environment and will not overwrite existing
# files.
# Please read the notice at the end of the script

PASSWORD_LENGTH=15
PASSWORDS=("middleware_selfservice_api" "middleware_registration_authority_api" "middleware_management_api" "mariadb_root" "mariadb_cluster" "mariadb_backup" "database_gateway" "database_deploy" "database_middleware" "database_keyserver" "database_tiqr")

SECRET_LENGTH=40
SECRETS=("gateway" "middleware" "ra" "selfservice" "tiqr" "keyserver")

SAML_CERTS=("gateway_saml_idp" "gateway_saml_sp" "gateway_tiqr_idp" "gateway_tiqr_sp" "selfservice_saml_sp" "selfservice_tiqr_sp" "ra_saml_sp" "ra_tiqr_sp" "tiqr_idp")

DOMAIN='stepup.example.com' # Domain for SSL certs

SSL_CERTS=("gateway" "ra" "selfservice" "manage" "middleware" "tiqr" "keyserver")

CWD=`pwd`
BASEDIR=`dirname $0`

function error_exit {
    echo "${1}"
    cd ${CWD}
    exit 1
}

function realpath {
    if [ ! -d ${1} ]; then
        return 1
    fi
    current_dir=`pwd`
    cd ${1}
    res=$?
    if [ $? -eq "0" ]; then
        path=`pwd`
        cd $current_dir
        echo $path
    fi
    return $res
}

BASEDIR=`realpath ${BASEDIR}`


# Process options
ENVIRONMENT_DIR=$1
if [ -z "${ENVIRONMENT_DIR}"  ]; then
    echo "Usage: $0 <environment directory>"
    exit 1;
fi
ENVIRONMENT_NAME=`basename ${ENVIRONMENT_DIR}`


TEMPLATE_DIR=`realpath ${BASEDIR}/../environments/template`
if [ $? -ne "0" ]; then
    error_exit "Could not change to template dir"
fi
echo "Using template from: ${TEMPLATE_DIR}"


if [ ! -e ${ENVIRONMENT_DIR} ]; then
    echo "Creating new environment directory"
    mkdir -p ${ENVIRONMENT_DIR}
fi

ENVIRONMENT_DIR=`realpath ${ENVIRONMENT_DIR}`
if [ $? -ne "0" ]; then
    error_exit "Could not change to environment dir"
fi
echo "Creating new environment in directory: ${ENVIRONMENT_DIR}"

# Copy inventory file into the new environment
INVENTORY_FILE=${ENVIRONMENT_DIR}/inventory
if [ ! -e  ${INVENTORY_FILE} ]; then
    echo "Creating inventory file"
    cp ${TEMPLATE_DIR}/inventory ${INVENTORY_FILE}
fi

# Copy group_vars directory into the new environment
GROUP_VARS_DIR=${ENVIRONMENT_DIR}/group_vars
if [ ! -e ${GROUP_VARS_DIR} ]; then
    echo "Creating group_vars directory"
    mkdir -p ${GROUP_VARS_DIR}
    cp ${TEMPLATE_DIR}/group_vars/*.yml ${GROUP_VARS_DIR}
fi


# Copy templates directory into the new environment
TEMPLATES_DIR=${ENVIRONMENT_DIR}/templates
if [ ! -e ${TEMPLATES_DIR} ]; then
    echo "Creating templates directory"
    mkdir -p ${TEMPLATES_DIR}
    cp -r ${TEMPLATE_DIR}/templates/* ${TEMPLATES_DIR}
fi


# Create keystore for encypting secrets
KEY_DIR=${ENVIRONMENT_DIR}/stepup-ansible-keystore

if [ ! -e ${KEY_DIR} ]; then
    ${BASEDIR}/create_keydir.sh ${KEY_DIR}
    if [ $? -ne "0" ]; then
        error_exit "Error creating keyset"
    fi
fi
echo "Using keydir: ${KEY_DIR}"


# Generate passwords
PASSWORD_DIR=${ENVIRONMENT_DIR}/password
if [ ! -e ${PASSWORD_DIR} ]; then
    echo "Creating password directory"
    mkdir -p ${PASSWORD_DIR}
fi

for pass in "${PASSWORDS[@]}"; do
    if [ ! -e "${PASSWORD_DIR}/${pass}" ]; then
        echo "Generating password for ${pass}"
        generated_password=`${BASEDIR}/gen_password.sh ${PASSWORD_LENGTH} ${KEY_DIR}`
        if [ $? -ne "0" ]; then
            error_exit "Error generating password"
        fi
        echo "${generated_password}" > ${PASSWORD_DIR}/${pass}
    fi
done
if [ ! -e "${PASSWORD_DIR}/empty_placeholder" ]; then
    echo "Creating empty_placeholder password"
    generated_password=`${BASEDIR}/gen_password.sh 0 ${KEY_DIR}`
    if [ $? -ne "0" ]; then
        error_exit "Error creating password"
    fi
    echo "${generated_password}" > ${PASSWORD_DIR}/empty_placeholder
fi

# Generate secrets
SECRET_DIR=${ENVIRONMENT_DIR}/secret
if [ ! -e ${SECRET_DIR} ]; then
    echo "Creating secret directory"
    mkdir -p ${SECRET_DIR}
fi

for secret in "${SECRETS[@]}"; do
    if [ ! -e "${SECRET_DIR}/${secret}" ]; then
        echo "Generating secret for ${secret}"
        generated_secret=`${BASEDIR}/gen_password.sh ${SECRET_LENGTH} ${KEY_DIR}`
        if [ $? -ne "0" ]; then
            error_exit "Error generating secret"
        fi
        echo "${generated_secret}" > ${SECRET_DIR}/${secret}
    fi
done


# Generate self-signed certs for SAML use
SAML_CERT_DIR=${ENVIRONMENT_DIR}/saml_cert
if [ ! -e ${SAML_CERT_DIR} ]; then
    echo "Creating saml_cert directory"
    mkdir -p ${SAML_CERT_DIR}
fi

cd ${SAML_CERT_DIR}
for cert in "${SAML_CERTS[@]}"; do
    if [ ! -e "${SAML_CERT_DIR}/${cert}.crt" -a "${SAML_CERT_DIR}/${cert}.key" ]; then
        echo "Creating SAML signing certificate and key for ${cert}"
        ${BASEDIR}/gen_selfsigned_cert.sh ${cert} "/CN=${cert}" ${KEY_DIR}
        if [ $? -ne "0" ]; then
            error_exit "Error creating SAML signing certificate"
        fi
    fi
done
cd ${CWD}

# Create Root CA for issueing SSL Server certs
CA_DIR=${ENVIRONMENT_DIR}/ca
if [ ! -e ${CA_DIR} ]; then
    ${BASEDIR}/create_ca.sh ${CA_DIR} "/CN=Root CA for Stepup ${ENVIRONMENT_NAME} environment"
    if [ $? -ne "0" ]; then
        error_exit "Error creating CA"
    fi
fi


# Create SSL server certificates
SSL_CERT_DIR=${ENVIRONMENT_DIR}/ssl_cert
if [ ! -e ${SSL_CERT_DIR} ]; then
    echo "Creating ss;_cert directory"
    mkdir -p ${SSL_CERT_DIR}
fi

cd ${SSL_CERT_DIR}
for cert in "${SSL_CERTS[@]}"; do
    if [ ! -e "${SSL_CERT_DIR}/${cert}.crt" -a "${SSL_CERT_DIR}/${cert}.key" ]; then
        echo "Creating SSL certificate and key for ${cert}"
        ${BASEDIR}/gen_ssl_server_cert.sh ${CA_DIR} ${cert} "/CN=${cert}.${DOMAIN}" ${KEY_DIR}
        if [ $? -ne "0" ]; then
            error_exit "Error creating SSL certificate"
        fi
    fi
done
cd ${CWD}

echo
echo "Created (or updated) passwords, secrets and certificates for a new environment

* All secrets (except the CA private key) are encrypted with a symmetic key that is stored in a "vault". The vault is
  located in ${KEY_DIR}
  You should keep this key separate from the environment. To do this:
  1) Move the stepup-ansible-keystore to another location
  2) Update vault_keydir in group_vars/all.yml to point to the new location

* Certificate authority
  The CA directory (${CA_DIR})
  contains the CA that is/was used for generating SSL server certificates. This CA is intended for testing purposes.
  The private key of the CA is stored *unencrypted* in ca-key.pem the CA directory. The CA directory is not required
  for running the ansible playbooks.

* You can use the encrypt.sh and encrypt-file.sh scripts to encrypt and decrypt the secrets.

* Complete the configuration of the environment by
  - updating the inventory file
  - updating the the .yml files with variables in the group_vars directory
  - updating the files in the templates directory
"
