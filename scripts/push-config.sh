#!/usr/bin/env bash

CWD=`pwd`

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

# Process options
DEPLOY_DIR=$1
shift
INVENTORY_FILE=$1
shift
WHAT=$1
shift
if [ -z "${DEPLOY_DIR}" -o  -z "${INVENTORY_FILE}" -o  -z "${WHAT}" ]; then
    echo "Usage: $0 <deploy directory> <inventory file> config|whitelist|institution (--branch <branch name>] | [--tag <tag name>]) [--limit <hosts>] [--verbose] [--allow-unclean]"
    echo "Deploys a new Stepup middleware 'config'(uration), 'whitelist' or 'institution' configuration."
    echo ""
    echo "<deploy directory> : Directory containing the playbooks. Read-only, git not required"
    echo "<inventory file>   : Path to inventory file to use. Must be a clean local git checkout. The local git repository"
    echo "                     is only updated when --tag or --branch is specified."
    echo "--limit <hosts>    : Limit to specified hosts (see: Ansible --limit option)"
    echo "--verbose          : Run ansible playbook in verbose mode"
    echo "--allow-unclean    : Allow unclean inventory repository to be used"
    echo "--branch <name>    : Update local git repository to head of the specified branch"
    echo "--tag <name>       : Update local git repository to the specified tag"
    echo ""
    echo "Note: For the deploy to succeed the current user needs access to the ssh private key used for deploys."
    echo "      The remote user that is used for deploys is specified in the 'app_deploy_user' ansible variable. This"
    echo "      is typically a different user, with a different ssh key, than is used for deploying the infrastructure."
    echo "      You can specify (additional) keys to be used for authentication in the ~/.ssh/config of the user that"
    echo "      runs this script using the 'IdentityFile' directive."
    exit 1;
fi

if [ ! -d "${DEPLOY_DIR}" ]; then
    error_exit "Deploy directory '${DEPLOY_DIR}' does not exist"
fi

if [ "${WHAT}" != "config" -a "${WHAT}" != "whitelist" -a "${WHAT}" != "institution" ]; then
    error_exit "Expected 'config', 'whitelist' or institution. Got: '${WHAT}'"
fi

DEPLOY_DIR=`realpath "${DEPLOY_DIR}"`
echo "Deploy directory: ${DEPLOY_DIR}"

if [ ! -e "${DEPLOY_DIR}/push-mw-${WHAT}.yml" ]; then
    error_exit "Missing 'push-mw-${WHAT}.yml' in the deploy dir."
fi


GIT_BRANCH='';
GIT_TAG='';
VERBOSE=0
ALLOW_UNCLEAN=0

while [[ $# > 0 ]]
do
option="$1"
shift

case $option in
    -t|--tag)
    GIT_TAG="$1"
    if [ -z "$1" ]; then
        error_exit "--tag option requires argument"
    fi
    shift
    ;;
    -b|--branch)
    GIT_BRANCH="$1"
    if [ -z "$1" ]; then
        error_exit "--branch option requires argument"
    fi
    shift
    ;;
    -l|--limit)
    LIMIT="$1"
    if [ -z "$1" ]; then
        error_exit "--limit option requires argument"
    fi
    shift
    ;;
    -v|--verbose)
    VERBOSE=1
    ;;
    --allow-unclean)
    ALLOW_UNCLEAN=1
    ;;
    *)
    error_exit "Unknown option: '${option}'"
    ;;
esac
done

if [ -n "${GIT_BRANCH}" -a -n "${GIT_TAG}" ]; then
    error_exit "Don't know how to handle both --branch and --tag"
fi

INVENTORY_DIR=`dirname "$INVENTORY_FILE"`
if [ "$?" -ne "0" ]; then
    error_exit "Error finding inventory dir"
fi

INVENTORY_DIR=`realpath "${INVENTORY_DIR}"`
echo "Inventory directory: ${INVENTORY_DIR}"

cd ${INVENTORY_DIR}
if [ "$?" -ne "0" ]; then
    error_exit "Error changing to inventory directory"
fi

GIT_ROOT=`git rev-parse --show-toplevel`
if [ "$?" -ne "0" ]; then
    error_exit "Error finding git root for inventory"
fi
echo "Using GIT root: ${GIT_ROOT}"

echo "Current branch: `git symbolic-ref -q --short HEAD`"
echo "Current commit: `git log -1 --pretty='%H'`, `git log -1 --pretty='%cd' --date=iso`"

echo "Fetching from origin"
git fetch origin
if [ "$?" -ne "0" ]; then
    error_exit "Error fetching repo for inventory"
fi

# Switch to specified branch / tag
if [ -n "${GIT_BRANCH}" ]; then
    # Verify that "GIT_BRANCH" exists on the remote
    echo "Using branch: ${GIT_BRANCH}"
    if [ `git ls-remote | grep -c "refs/heads/${GIT_BRANCH}"` -ne "1" ]; then
        error_exit "No such branch on remote: '${GIT_BRANCH}'"
    fi
    # Switch to "GIT_BRANCH" locally and ensure that it is tracking the branch with the same name on the remote
    git checkout -B ${GIT_BRANCH} --track "origin/${GIT_BRANCH}"
    if [ "$?" -ne "0" ]; then
        error_exit "Error setting branch"
    fi
    # Reset local branch to match remote exactly
    git reset --hard "origin/${GIT_BRANCH}"
    if [ "$?" -ne "0" ]; then
        error_exit "Error restting branch"
    fi
fi
if [ -n "${GIT_TAG}" ]; then
    echo "Using tag: ${GIT_TAG}"
    if [ -z "`git tag --list ${GIT_TAG}`" ]; then
        error_exit "No such tag: '${GIT_TAG}'"
    fi
    git checkout "tags/${GIT_TAG}"
    if [ "$?" -ne "0" ]; then
        error_exit "Error setting tag"
    fi
fi

# Check whether repo is clean
# Get status, ignoring untracked files
output=`git status --porcelain -uno`
if [ "$?" -ne "0" ]; then

    error_exit "git status failed"
fi
if [ ! -z "${output}" ]; then
    git status --porcelain -uno
    if [ "${ALLOW_UNCLEAN}" -ne "1" ]; then
        error_exit "git tree is not clean"
    fi
        echo "Allowing unclean tree because the --allow-unclean option is specified"
fi

echo "Deploying branch: `git symbolic-ref -q --short HEAD`"
echo "Deploying commit: `git log -1 --pretty='%H'`, `git log -1 --pretty='%cd' --date=iso`"

cd ${CWD}

if [ ! -e "${INVENTORY_FILE}" ]; then
    error_exit "Inventory file '${INVENTORY_FILE}' does not exist"
fi

ansible_command="${DEPLOY_DIR}/push-mw-${WHAT}.yml -i ${INVENTORY_FILE}"
if [ ! -z "${LIMIT}" ]; then
    ansible_command="${ansible_command} -l ${LIMIT}"
fi
if [ "${VERBOSE}" -eq "1" ]; then
    ansible_command="${ansible_command} -vvvv"
fi

ansible-playbook ${ansible_command}
if [ "$?" -ne "0" ]; then
    error_exit "Deploy failed"
fi

exit 0