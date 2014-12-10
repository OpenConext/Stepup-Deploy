#!/bin/bash

CWD=`pwd`
COMPONENTS=("Stepup-Middleware" "Stepup-Gateway" "Stepup-SelfService" "Stepup-RA")
UNARCHIVE=1

function error_exit {
    echo "${1}"
    cd ${CWD}
    exit 1
}


# Process options
COMPONENT_TARBALL=$1
shift
if [ -z "${COMPONENT_TARBALL}"  ]; then
    echo "Usage: $0 <component tarball>"
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
    *)
    error_exit "Unkown option: '${option}'"
    ;;
esac
done

found=0
for comp in "${COMPONENTS[@]}"; do
    regex="^($comp).*(\.tar\.bz2)$"
    if [[ $COMPONENT_TARBALL =~ $regex ]]; then
        found=1
        COMPONENT=$comp
    fi
done
if [ "$found" -ne "1" ]; then
    error_exit "Component must end in .tar.bz2 and start with one of: ${COMPONENTS[*]}"
fi

COMPONENT=`echo ${COMPONENT} | tr '[:upper:]' '[:lower:]'`
echo "Deploying component: $COMPONENT"
echo "Unarchive=${UNARCHIVE}"

cd Stepup-Deploy

ansible-playbook deploy.yml --limit "app1*" --tags $COMPONENT -e "component_tarball_name=../$COMPONENT_TARBALL" -e "component_unarchive=${UNARCHIVE}"

cd ${CWD}
