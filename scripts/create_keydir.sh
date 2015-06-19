#!/bin/bash

CWD=`pwd`
BASEDIR=`dirname $0`

function error_exit {
    echo "${1}"
    rm -r ${KEY_DIR}
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

KEYCZART=`which keyczart 2>/dev/null`
if [ -z "${KEYCZART}" -o ! -x "${KEYCZART}" ]; then
    echo "keyczart is not in path or not executable. Please install keyczart"
    echo "See: http://keyczar.org"
    exit 1;
fi

echo "Using keyczart: ${KEYCZART}"

# Process options
KEY_DIR=$1
if [ -z "${KEY_DIR}"  ]; then
    echo "Usage: $0 <key directory>"
    exit 1;
fi

if [ -e ${KEY_DIR} ]; then
    echo "Key directory already exists. Leaving"
    exit 1;
fi

echo "Creating keydir"
mkdir -p -v ${KEY_DIR}
if [ $? -ne "0" ]; then
    echo "Error creating keydir"
    exit 1
fi

KEY_DIR=`realpath ${KEY_DIR}`
echo "Using keydir: ${KEY_DIR}"

echo "Creating keyset 'stepup'"
# Create new, empty, keyset
${KEYCZART} create --location=${KEY_DIR} --purpose=crypt --name=stepup
if [ $? -ne "0" ]; then
    error_exit "Error creating keyset"
fi

echo "Adding new key"
# Generate new key, add it to the keyset, and set this to be the active key
${KEYCZART} addkey --location=${KEY_DIR} --status=primary
if [ $? -ne "0" ]; then
    error_exit "Error adding key"
fi

echo "Done. Created new key and keyset: ${KEY_DIR}"

exit 0
