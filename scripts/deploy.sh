#!/bin/bash

CWD=`pwd`
BASEDIR=`dirname $0`
COMPONENTS=("Stepup-Middleware" "Stepup-Gateway" "Stepup-SelfService" "Stepup-RA")
UNARCHIVE=1
VERBOSE=0
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


# Process options
COMPONENT_TARBALL=$1
shift
if [ -z "${COMPONENT_TARBALL}"  ]; then
    echo "Usage: $0 <component tarball> [options]"

    echo "-i|--inventory <FILE>  Location of ansible inventory file"
    echo "-l|--limit: <SUBSET>   Limit option to pass to ansible (limits hosts)"
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

COMPONENT=`echo ${COMPONENT} | tr '[:upper:]' '[:lower:]'`
echo "Deploying component: ${COMPONENT}"
echo "Unsing inventory: ${INVENTORY}"
echo "Host limit: ${LIMIT}"
echo "unarchive=${UNARCHIVE}"
echo "verbose=${VERBOSE}"
echo

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


playbook_root="${BASEDIR}/.."
cd ${playbook_root}

ansible-playbook ./deploy.yml ${verbose_flag} ${inventory_option} ${limit_option} --tags $COMPONENT -e "component_tarball_name=${COMPONENT_TARBALL}" -e "component_unarchive=${UNARCHIVE}"

cd ${CWD}
