#!/usr/bin/env bash

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

if [ $# -lt 1 ]; then
    echo "Usage $0 <environment directory> [--keyczar-dir <keyczar-directory>] [--vault-password-file <vault password filename>]"
    echo ""
    echo "This script migrates the secrets that are encrypted using keyczar to secrets encrypted using Ansible vault."
    echo "The scrips decrypts the secrect using the keyczar key and then encrypts them using Ansible vault."
    echo ""
    echo "By default the vault password is read from <environment directory>/stepup-ansible-vault-password and the"
    echo "keyczar key is read from <environment dir>/stepup-ansible-keystore"
    echo "You can override these locations using the --vault-password-file and --keyczar-dir options respectively."
    echo ""
    exit 1
fi


# The environment directory
ENVIRONMENT_DIR=$1
shift

if [ ! -d ${ENVIRONMENT_DIR} ]; then
    error_exit "Environment directory not found"
fi
ENVIRONMENT_DIR=`realpath ${ENVIRONMENT_DIR}`
echo ""
echo "Using environment directory: $ENVIRONMENT_DIR"


# Set default keyczar dir and vault password file locations
KEYCZAR_DIR=${ENVIRONMENT_DIR}/stepup-ansible-keystore
VAULT_PASSWORD_FILE=${ENVIRONMENT_DIR}/stepup-ansible-vault-password

# Process option(s)
while [[ $# > 0 ]]
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
    VAULT_PASSWORD_FILE="$1"
    if [ -z "$1" ]; then
        error_exit "--vault-password-file option requires argument"
    fi
    shift
    ;;
    *)
    error_exit "Unknown option: '${option}'"
    ;;
esac
done

if [ ! -d ${KEYCZAR_DIR} ]; then
    error_exit "Keyczar directory not found"
fi
if [ ! -f ${VAULT_PASSWORD_FILE} ]; then
    error_exit "Ansible vault password file not found"
fi

echo "Using keyczar directory: ${KEYCZAR_DIR}"
echo "Using Ansible vault password file: ${VAULT_PASSWORD_FILE}"

echo ""
echo "WARNING: Reencryption will overwrite the encrypted files with the newly encrypted versions!"
echo ""
read -p "Are you sure you want to continue (Y/N)? " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

# List of globs of encrypted files
ENCRYPTED_FILE_GLOBS=("password/*" "saml_cert/*.key" "secret/*" "ssh/*.key" "ssl_cert/*.key")

skipped=0
converted=0
inspected=0
errors=0

for fileglob in ${ENCRYPTED_FILE_GLOBS[@]}; do
  for file in ${ENVIRONMENT_DIR}/${fileglob}; do
    echo Inspecting "${file}"
    (( inspected++ ))

    # Check if file was already converted
    # Read first 14 characters from file into $chars to see if it matches $ANSIBLE_VAULT
    read -n 14 chars < ${file}
    if [ $? -ne "0" ]; then
      echo "Error reading file"
      (( errors++ ))
      continue
    fi
    if [ ${chars} == '$ANSIBLE_VAULT' ]; then
      echo "File looks like it was already converted. Skipping"
      (( skipped++ ))
      continue
    fi


    # A Keyczar encrypted file has a header that should always start with an 'A'
    # This checks if it at least looks like an keyczar encrypted file
    # Read first character from file into $char
    read -n 1 char < ${file}
    if [ $? -ne "0" ]; then
      echo "Error reading file"
      (( errors++ ))
      continue
    fi

    if [ ${char} != "A" ]; then
      echo "ERROR: File does not look like a keyczar file"
      (( errors++ ))
      continue
    fi

    temp=`mktemp /tmp/migrate_environment.XXXXXX`

    # Read and decrypt file
    ${BASEDIR}/encrypt-file.sh -d -f ${file} ${KEYCZAR_DIR} > ${temp}
    if [ $? -ne "0" ]; then
      rm ${temp}
      echo "Error decrypting file"
      (( errors++ ))
      continue
    fi

    ansible-vault encrypt --vault-password-file=${VAULT_PASSWORD_FILE} ${temp}
    if [ $? -ne "0" ]; then
      rm ${temp}
      echo "Error encrypting file"
      (( errors++ ))
      continue
    fi

    mv ${temp} ${file}
    if [ $? -ne "0" ]; then
      rm ${temp}
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