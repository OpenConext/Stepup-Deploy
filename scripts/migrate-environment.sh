#!/usr/bin/env bash

CWD=$(pwd)
BASEDIR=$(dirname "$0")

function error_exit {
    echo "${1}"
    cd "${CWD}"
    exit 1
}

function realpath {
    if [ ! -d "${1}" ]; then
        return 1
    fi
    current_dir=$(pwd)
    cd "${1}"
    res=$?
    if [ $? -eq "0" ]; then
        path=$(pwd)
        cd "$current_dir"
        echo "$path"
    fi
    return $res
}

if [ $# -lt 1 ]; then
    echo "Usage $0 <environment directory> [--keyczar-dir <keyczar-directory>] [--vault-label <vault-label] [--vault-password-file <vault password filename>]"
    echo ""
    echo "This script migrates the secrets that are encrypted using keyczar to secrets encrypted using Ansible vault."
    echo "The scrips decrypts the secret using the keyczar key and then encrypts them using the specified Ansible vault-id name and password."
    echo ""
    echo "By default the vault-id is set to 'stepup', the vault-password-file is set to '<environment directory>/stepup-ansible-vault-password'"
    echo "and the keyczar key is read from <environment dir>/stepup-ansible-keystore"
    echo "You can override echo of the parameters using the --vault-id, --vault-password-file and --keyczar-dir options respectively."
    echo ""
    echo "OPTIONS:"
    echo "--keyczar-dir <keyczar-directory>                The directory with the keyczar key used for decryption"
    echo "--vault-label <vault-label>                      The name (label) of the Ansible vault. Identifies the password used"
    echo "--vault-password-file <vault password filename>  The path to the file with the password used for encryption"
    echo ""
    echo "The vault-label is incorporated (in plain text) in the encrypted blob. Recommendation is to set this to something that identifies"
    echo "the environment."
    exit 1
fi


# The environment directory
ENVIRONMENT_DIR=$1
shift

if [ ! -d "${ENVIRONMENT_DIR}" ]; then
    error_exit "Environment directory not found"
fi
ENVIRONMENT_DIR=$(realpath "${ENVIRONMENT_DIR}")
echo ""
echo "Using environment directory: $ENVIRONMENT_DIR"


# Set default keyczar dir and vault password file locations
KEYCZAR_DIR="${ENVIRONMENT_DIR}/stepup-ansible-keystore"
STEPUP_VAULT_LABEL=stepup
ANSIBLE_VAULT_PASSWORD_FILE=${ENVIRONMENT_DIR}/stepup-ansible-vault-password

# Process option(s)
while [[ $# -gt 0 ]]
do
option="$1"
shift
case $option in
    --keyczar-dir)
    KEYCZAR_DIR="$1"
    if [ -z "$1" ]; then
        error_exit "--keyczar-dir option requires argument"
    fi
    shift
    ;;
    --vault-password-file)
    ANSIBLE_VAULT_PASSWORD_FILE="$1"
    if [ -z "$1" ]; then
        error_exit "--vault-password-file option requires argument"
    fi
    shift
    ;;
    --vault-label)
    STEPUP_VAULT_LABEL="$1"
    if [ -z "$1" ]; then
        error_exit "--vault-label option requires argument"
    fi
    shift
    ;;
    *)
    error_exit "Unknown option: '${option}'"
    ;;
esac
done

if [ ! -d "${KEYCZAR_DIR}" ]; then
    error_exit "Error: Keyczar directory not found"
fi
if [ ! -f "${ANSIBLE_VAULT_PASSWORD_FILE}" ]; then
    echo "Ansible vault password file not found: ${ANSIBLE_VAULT_PASSWORD_FILE}"
    read -p "Do you want to create a new vault password file (Y/N)? " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        error_exit "Abort: vault password file not created"
    fi
    "${BASEDIR}"/gen_password.sh 15 > "${ANSIBLE_VAULT_PASSWORD_FILE}"
    if [ $? -ne "0" ]; then
        error_exit "Error generating Ansible Vault password"
    fi
    echo "Generated Ansible Vault password file"
fi


echo "Using keyczar directory: ${KEYCZAR_DIR}"
echo "Using Ansible vault-label: ${STEPUP_VAULT_LABEL}"
echo "Using Ansible vault-password-file: ${ANSIBLE_VAULT_PASSWORD_FILE}"

echo ""
echo "WARNING: Reencryption will overwrite the encrypted files with the newly encrypted versions!"
echo ""
read -p "Are you sure you want to continue (Y/N)? " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

# Location of an empty ansible configuration file, used to disable system specific ansible configuration that may
# interfere with our use of ansible-vault
EMPTY_ANSIBLE_CONFIG_FILE=${BASEDIR}/empty_ansible.cfg;

# List of globs of encrypted files
ENCRYPTED_FILE_GLOBS=("password/*" "saml_cert/*.key" "secret/*" "ssh/*.key" "ssl_cert/*.key")

skipped=0      # Skipped: files that are already encrypted using ansible vault
converted=0    # Converted: files that were successfully migrated from keyczar to Ansible vault
inspected=0    # Inspected: number of files that were read
errors=0       # Errors: number of files for which the migration failed

for fileglob in "${ENCRYPTED_FILE_GLOBS[@]}"; do
  for file in "${ENVIRONMENT_DIR}"/${fileglob}; do
    echo Inspecting "${file}"
    (( inspected++ ))

    # Check if file was already converted
    # Read first 14 characters from file into $chars to see if it matches $ANSIBLE_VAULT
    read -r -n 14 chars < "${file}"
    if [ $? -ne "0" ]; then
      echo "Error reading file"
      (( errors++ ))
      continue
    fi
    # shellcheck disable=SC2016
    if [ "${chars}" == '$ANSIBLE_VAULT' ]; then
      echo "File looks like it was already converted to Ansible vault. Skipping"
      (( skipped++ ))
      continue
    fi


    # A Keyczar encrypted file has a header that should always start with an 'A'
    # This checks if it at least looks like an keyczar encrypted file
    # Read first character from file into $char
    read -r -n 1 char < "${file}"
    if [ $? -ne "0" ]; then
      echo "Error reading file"
      (( errors++ ))
      continue
    fi

    if [ "${char}" != "A" ]; then
      echo "ERROR: File does not look like a keyczar file"
      (( errors++ ))
      continue
    fi

    temp=$(mktemp /tmp/migrate_environment.XXXXXX)

    # Read and decrypt file
    "${BASEDIR}/encrypt-file.sh" -d -f "${file}" "${KEYCZAR_DIR}" > "${temp}"
    if [ $? -ne "0" ]; then
      rm "${temp}"
      echo "Error decrypting file"
      (( errors++ ))
      continue
    fi

    ANSIBLE_CONFIG=${EMPTY_ANSIBLE_CONFIG_FILE}; ansible-vault encrypt --vault-id="${STEPUP_VAULT_LABEL}@${ANSIBLE_VAULT_PASSWORD_FILE}" "${temp}"
    if [ $? -ne "0" ]; then
      rm "${temp}"
      echo "Error encrypting file"
      (( errors++ ))
      continue
    fi

    mv "${temp}" "${file}"
    if [ $? -ne "0" ]; then
      rm "${temp}"
      echo "Error replacing encrypted file"
      (( errors++ ))
      continue
    fi

    echo "Done"

  done
done

echo ""
echo "Inspected files: $inspected"
echo "Converted files: $converted"
echo "Skipped files: $skipped"
echo "Error'ed files: $errors"
echo ""
echo "To enable decryption of the Ansible vault encrypted files without having to specify the password you can add"
echo "the password to your ansible.cfg file by setting vault_identity_list in the [default] section:"
echo ""
echo "vault_identity_list = ${STEPUP_VAULT_LABEL}@${ANSIBLE_VAULT_PASSWORD_FILE}".
echo ""
echo "You can add multiple identities by separating them with a comma. E.g."
echo "vault_identity_list = id1@password-file, id2@password-file"
