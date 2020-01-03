#!/usr/bin/env bash

CWD=`pwd`
BASEDIR=`dirname $0`
COMPONENTS=("Stepup-Middleware" "Stepup-Gateway" "Stepup-SelfService" "Stepup-RA" "Stepup-tiqr" "Stepup-Webauthn" "oath-service-php" "Stepup-Azure-MFA")
UNARCHIVE=1
VERBOSE=0
ASKSUDO=""
INVENTORY=""
LIMIT=""

function error_exit {
    echo "${1}"
    if [ -n "${TMP_ARCHIVE_DIR}" -a -d "${TMP_ARCHIVE_DIR}" ]; then
        rm -r "${TMP_ARCHIVE_DIR}"
    fi
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


# Process options
COMPONENT_TARBALL=$1
if [ ! -f ${COMPONENT_TARBALL} ]; then
    error_exit "FIle not found: '${COMPONENT_TARBALL}'"
fi
shift
if [ -z "${COMPONENT_TARBALL}"  ]; then
    echo "Usage: $0 <component tarball> [options]"

    echo "-i|--inventory <FILE>  Location of ansible inventory file"
    echo "-l|--limit: <SUBSET>   Limit option to pass to ansible (limits hosts)"
    echo "-K|--ask-sudo-pass     Ask for sudo password"
    echo "-n|--no-unarchive      Skip uploading and unarchiving the tarball on the remote"
    echo "-v|--verbose           Pass \"-vvvv\" verbosity to ansible"
    echo "Supported components: ${COMPONENTS[*]}"
    exit 1;
fi

while [[ $# > 0 ]]
do
option="$1"
shift

case $option in
    -n|--no-unarchive)
    UNARCHIVE="0"
    ;;
    -K|--ask-sudo-pass)
    ASKSUDO="-K"
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
    cd ${CWD}
    cd `dirname ${INVENTORY}`
    INVENTORY=`pwd`/`basename ${INVENTORY}`
    cd ${CWD}
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

component_tarball_basename=`basename ${COMPONENT_TARBALL}`
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

# Get absolute path to component tarball
cd ${CWD}
cd `dirname ${COMPONENT_TARBALL}`
COMPONENT_TARBALL=`pwd`/`basename ${COMPONENT_TARBALL}`
cd ${CWD}

COMPONENT=`echo ${COMPONENT} | tr '[:upper:]' '[:lower:]'`
echo "Deploying component: ${COMPONENT}"
echo "Unsing inventory: ${INVENTORY}"
echo "Host limit: ${LIMIT}"
echo "unarchive=${UNARCHIVE}"
echo "verbose=${VERBOSE}"
echo

if [ ${UNARCHIVE} -eq "1" ]; then
    echo "Testing ${COMPONENT_TARBALL}"

    # Sanity check tar file
    TMP_ARCHIVE_DIR=`mktemp -d "/tmp/${COMPONENT}.XXXXXXXX"`
    if [ $? -ne "0" ]; then
        error_exit "Could not create temp dir"
    fi

    # Extract tarball
    bunzip2 -k -q -c "${COMPONENT_TARBALL}" > ${TMP_ARCHIVE_DIR}/component.tar
    if [ $? -ne "0" ]; then
        error_exit "bunzip2 failed"
    fi

    # Untar it
    tar -xf ${TMP_ARCHIVE_DIR}/component.tar -C ${TMP_ARCHIVE_DIR}
    if [ $? -ne "0" ]; then
        error_exit "tar failed"
    fi

    rm -r ${TMP_ARCHIVE_DIR}
fi

# Start ansible deploy
echo "Starting deploy"

verbose_flag=""
if [ "${VERBOSE}" -eq "1" ]; then
    verbose_flag="-vvvv"
fi

inventory_option=""
if [ -n "${INVENTORY}" ]; then
    inventory_option="-i ${INVENTORY}"
fi

limit_option=""
if [ -n "${LIMIT}" ]; then
    limit_option="-l ${LIMIT}"
fi


deploy_playbook_dir=`realpath "${BASEDIR}/../"`


if [ "${VERBOSE}" -eq "1" ]; then
    echo ansible-playbook ${deploy_playbook_dir}/deploy.yml ${verbose_flag} ${inventory_option} ${limit_option} --tags $COMPONENT -e "component_tarball_name=${COMPONENT_TARBALL}" -e "component_unarchive=${UNARCHIVE}"
fi

ansible-playbook ${deploy_playbook_dir}/deploy.yml ${verbose_flag} ${inventory_option} ${limit_option} --tags $COMPONENT -e "component_tarball_name=${COMPONENT_TARBALL}" -e "component_unarchive=${UNARCHIVE}" $ASKSUDO
res=$?
cd ${CWD}

exit $res
