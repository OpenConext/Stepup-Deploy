#!/usr/bin/env bash

CWD=$(pwd)
BASEDIR=$(dirname "$0")
COMPONENTS=("Stepup-Middleware" "Stepup-Gateway" "Stepup-SelfService" "Stepup-RA" "Stepup-tiqr" "Stepup-Webauthn" "oath-service-php" "Stepup-Azure-MFA")
CONFIG_ONLY_COMPONENTS=("Stepup-Webauthn" "Stepup-Azure-MFA")
UNARCHIVE=1
CONFIGONLY=0
VERBOSE=0
ASKSUDO=""
INVENTORY=""
LIMIT=""

function error_exit {
    echo "${1}"
    if [ -n "${TMP_ARCHIVE_DIR}" ] && [ -d "${TMP_ARCHIVE_DIR}" ]; then
        rm -r "${TMP_ARCHIVE_DIR}"
    fi
    # shellcheck disable=SC2164
    cd "${CWD}"
    exit 1
}


function realpath {
    if [ ! -d "${1}" ]; then
        return 1
    fi
    current_dir=$(pwd)
    # shellcheck disable=SC2164
    cd "${1}"
    res=$?
    if [ $? -eq "0" ]; then
        path=$(pwd)
        # shellcheck disable=SC2164
        cd "$current_dir"
        echo "$path"
    fi
    return $res
}


# Process options
COMPONENT_TARBALL=$1
shift
if [ -z "${COMPONENT_TARBALL}"  ]; then
    echo "Usage: $0 <component tarball> [options]"

    echo "-i|--inventory <FILE>  Location of ansible inventory file"
    echo "-l|--limit: <SUBSET>   Limit option to pass to ansible (limits hosts)"
    echo "-K|--ask-sudo-pass     Ask for sudo password"
    echo "-n|--no-unarchive      Skip uploading and unarchiving the tarball on the remote"
    echo "-c|--config-only       Only update the components configuration files (only for: ${CONFIG_ONLY_COMPONENTS[*]})"
    echo "-v|--verbose           Pass \"-vvvv\" verbosity to ansible"
    echo "Supported components: ${COMPONENTS[*]}"
    exit 1;
fi
if [ ! -f "${COMPONENT_TARBALL}" ]; then
    error_exit "File not found: '${COMPONENT_TARBALL}'"
fi


while [[ $# -gt 0 ]]
do
option="$1"
shift

case $option in
    -n|--no-unarchive)
    UNARCHIVE="0"
    ;;
    -c|--config-only)
    CONFIGONLY="1"
    UNARCHIVE="0"
    ;;
    -K|--ask-sudo-pass)
    ASKSUDO="-K"
    ;;
    --vault-password-file)
    VAULT_PASSWORD_FILE="$1"
    shift
    if [ -z "${VAULT_PASSWORD_FILE}" ]; then
        error_exit "--vault-password-file option requires an argument"
    fi
    ;;
    -v|--verbose)
    VERBOSE="1"
    ;;
    -i|--inventory)
    INVENTORY="$1"
    shift
    if [ -z "${INVENTORY}" ]; then
        error_exit "-i|--inventory option requires an argument"
    fi
    if [ ! -f "${INVENTORY}" ]; then
        error_exit "Inventory file '${INVENTORY}' not found"
    fi
    # Get absolute path to inventory
    cd "${CWD}" || error_exit "Error changing directory"
    cd "$(dirname "${INVENTORY}")"  || error_exit "Error changing directory"
    INVENTORY=$(pwd)/$(basename "${INVENTORY}")
    cd "${CWD}" || error_exit "Error changing directory"
    ;;
    -l|--limit)
    LIMIT="$1"
    shift
    if [ -z "${LIMIT}" ]; then
        error_exit "-l|--limit option requires an argument"
    fi
    ;;
    *)
    error_exit "Unkown option: '${option}'"
    ;;
esac
done

component_tarball_basename=$(basename "${COMPONENT_TARBALL}")
found=0
for comp in "${COMPONENTS[@]}"; do
    regex="^($comp).*(\.tar\.bz2)$"
    if [[ $component_tarball_basename =~ $regex ]]; then
        found=1
        COMPONENT=$comp
    fi
done
if [ "$found" -ne "1" ]; then
    error_exit "Tarball to deploy must end in .tar.bz2 and start with one of: ${COMPONENTS[*]}"
fi

# If -c is set, and component does not support -c, error here
if [ ${CONFIGONLY} -eq "1" ]; then
  # "${CONFIG_ONLY_COMPONENTS[*]}" concatenates all strings in CONFIG_ONLY_COMPONENTS and the comparison with *"${COMPONENT}"* does a substring search
  # This behaves correctly here because we have already assured that COMPONENT is one of COMPONENTS
  if [[ ! "${CONFIG_ONLY_COMPONENTS[*]}" = *"${COMPONENT}"* ]]; then
    error_exit "${COMPONENT} does not support -c|--config-only"
  fi
fi

# Get absolute path to component tarball
cd "${CWD}" || error_exit "Error changing directory"
cd "$(dirname "${COMPONENT_TARBALL}")" || error_exit "Error changing directory"
COMPONENT_TARBALL=$(pwd)/$(basename "${COMPONENT_TARBALL}")
cd "${CWD}" || error_exit "Error changing directory"

COMPONENT=$(echo "${COMPONENT}" | tr '[:upper:]' '[:lower:]')
echo "Deploying component: ${COMPONENT}"
echo "Using inventory: ${INVENTORY}"
echo "Host limit: ${LIMIT}"
echo "unarchive=${UNARCHIVE}"
echo "config only=${CONFIGONLY}"
echo "verbose=${VERBOSE}"
echo

if [ ${UNARCHIVE} -eq "1" ]; then
    echo "Testing ${COMPONENT_TARBALL}"

    # Sanity check tar file
    TMP_ARCHIVE_DIR=$(mktemp -d "/tmp/${COMPONENT}.XXXXXXXX")
    if [ $? -ne "0" ]; then
        error_exit "Could not create temp dir"
    fi

    # Extract tarball
    bunzip2 -k -q -c "${COMPONENT_TARBALL}" > "${TMP_ARCHIVE_DIR}/component.tar"
    if [ $? -ne "0" ]; then
        error_exit "bunzip2 failed"
    fi

    # Untar it
    tar -xf "${TMP_ARCHIVE_DIR}/component.tar" -C "${TMP_ARCHIVE_DIR}"
    if [ $? -ne "0" ]; then
        error_exit "tar failed"
    fi

    rm -r "${TMP_ARCHIVE_DIR}"
fi

# Start ansible deploy
echo "Starting deploy"

verbose_flag=""
if [ "${VERBOSE}" -eq "1" ]; then
    verbose_flag="-vvvv"
fi

configonly_flag="-e configonly=False"
if [ "${CONFIGONLY}" -eq "1" ]; then
    configonly_flag="-e configonly=True"
fi


inventory_option=""
if [ -n "${INVENTORY}" ]; then
    inventory_option="-i ${INVENTORY}"
fi

limit_option=""
if [ -n "${LIMIT}" ]; then
    limit_option="-l ${LIMIT}"
fi

vault_password_file_option=""
if [ -n "${VAULT_PASSWORD_FILE}" ]; then
    vault_password_file_option="--vault-password-file ${VAULT_PASSWORD_FILE}"
fi

deploy_playbook_dir=$(realpath "${BASEDIR}/../")


if [ "${VERBOSE}" -eq "1" ]; then
    echo ansible-playbook "${deploy_playbook_dir}/deploy.yml" ${verbose_flag} ${inventory_option} ${limit_option} ${configonly_flag} --tags "${COMPONENT}" -e "component_tarball_name=${COMPONENT_TARBALL}" -e "component_unarchive=${UNARCHIVE}" ${ASKSUDO} $vault_password_file_option
fi

ansible-playbook "${deploy_playbook_dir}/deploy.yml" ${verbose_flag} ${inventory_option} ${limit_option} ${configonly_flag} --tags "${COMPONENT}" -e "component_tarball_name=${COMPONENT_TARBALL}" -e "component_unarchive=${UNARCHIVE}" ${ASKSUDO} $vault_password_file_option
res=$?
# shellcheck disable=SC2164
cd "${CWD}"

exit $res
