#!/bin/bash

CWD=`pwd`
COMPONENTS=("Stepup-Middleware" "Stepup-Gateway" "Stepup-SelfService" "Stepup-RA")
DEFAULT_BRANCH=develop
BUILD_ENV=build

function error_exit {
    echo "${1}"
    if [ -n "${TMP_ARCHIVE_DIR}" -a -d "${TMP_ARCHIVE_DIR}" ]; then
        rm -r "${TMP_ARCHIVE_DIR}"
    fi
    cd ${CWD}
    exit 1

}


# Process options
COMPONENT=$1
shift
if [ -z "${COMPONENT}"  ]; then
    echo "Usage: $0 <component> ([--branch <branch name>] | [--tag <tag name>]) [--env <symfony env>]"
    echo "Components: ${COMPONENTS[*]}"
    exit 1;
fi

found=0
for comp in "${COMPONENTS[@]}"; do
    if [ "$comp" = "${COMPONENT}" ]; then
        found=1
    fi
done
if [ "$found" -ne "1" ]; then
    error_exit "Component must be one of: ${COMPONENTS[*]}"

fi

GIT_BRANCH='';
GIT_TAG='';

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
    --env)
    BUILD_ENV="$1"
    if [ -z "$1" ]; then
        error_exit "--env option requires argument"
    fi
    shift
    ;;
    *)
    error_exit "Unkown option: '${option}'"
    ;;
esac
done

if [ -n "${GIT_BRANCH}" -a -n "${GIT_TAG}" ]; then
    error_exit "Don't know how to handle both --branch and --tag"
fi
if [ -z "${GIT_BRANCH}" -a -z "${GIT_TAG}" ]; then
    GIT_BRANCH=${DEFAULT_BRANCH}
fi

echo "Component: ${COMPONENT}"

# Checkout / update component from git 
if [ ! -d "$COMPONENT" ]; then
    cd ${CWD}
    git clone git@github.com:SURFnet/${COMPONENT}.git
else
    cd ${CWD}/${COMPONENT}
    git fetch --all --tags
fi
if [ "$?" -ne "0" ]; then
    error_exit "Error cloning / fetching repo"
fi 

cd ${CWD}/${COMPONENT}

# Switch to specified branch / tag
if [ -n "${GIT_BRANCH}" ]; then
    echo "Using branch: ${GIT_BRANCH}"
    if [ `git ls-remote | grep -c "refs/heads/${GIT_BRANCH}"` -ne "1" ]; then
        error_exit "No such branch on remote: '${GIT_BRANCH}'"
    fi
    git checkout "origin/${GIT_BRANCH}"
    if [ "$?" -ne "0" ]; then
        error_exit "Error setting branch"
    fi
fi
if [ -n "${GIT_TAG}" ]; then
    echo "Using tag: ${GIT_TAG}"
    if [ -z "`git tag --list ${GIT_TAG}`" ]; then
        echo "No such tag: '${GIT_TAG}'"
        exit 1
    fi
    git checkout "tags/${GIT_TAG}"
    if [ "$?" -ne "0" ]; then
        error_exit "Error setting tag"
    fi
fi


# Make name for archive based on git commit hash and date
COMMIT_HASH=`git log -1 --pretty="%H"`
COMMIT_DATE=`git log -1 --pretty="%cd" --date=iso`
COMMIT_Z_DATE=`php -r "echo gmdate('YmdHis\Z', strtotime('${COMMIT_DATE}'));"`
NAME=${COMPONENT}-${GIT_HEAD}${GIT_TAG}${GIT_BRANCH}-${COMMIT_Z_DATE}-${COMMIT_HASH}
NAME=`echo "${NAME}" | tr / _`


# Find a composer to use
COMPOSER_PATH=`which composer.phar`
if [ -z "${COMPOSER_PATH}" ]; then
    COMPOSER_PATH=`which composer`
    if [ -z "${COMPOSER_PATH}" ]; then
        error_exit "Cannot find composer.phar"
    fi
fi
COMPOSER_VERSION=`${COMPOSER_PATH} --version`
echo "Using composer: ${COMPOSER_PATH}"
echo "Composer version: ${COMPOSER_VERSION}"
echo "Using symfony env: ${BUILD_ENV}"

export SYMFONY_ENV=${BUILD_ENV}
#export SYMFONY_ENV=build
${COMPOSER_PATH} install --prefer-dist --ignore-platform-reqs --no-dev --no-interaction --optimize-autoloader
if [ $? -ne "0" ]; then
    error_exit "Composer install failed"
fi

#php app/console assets:install --symlink
#if [ $? -ne "0" ]; then
#    error_exit "console command 'assets:install' failed"
#fi

#php app/console mopa:bootstrap:symlink:less
#if [ $? -ne "0" ]; then
#    error_exit "console command: 'mopa:bootstrap:symlink:less' failed"
#fi

TMP_ARCHIVE_DIR=`mktemp -d "/tmp/${COMPONENT}.XXXXXXXX"`
if [ $? -ne "0" ]; then
    error_exit "Could not create temp dir"
fi


${COMPOSER_PATH} archive --format=tar --dir="${TMP_ARCHIVE_DIR}" --no-interaction
if [ $? -ne "0" ]; then
    error_exit "Composer achive failed"
fi

ARCHIVE_TMP_NAME=`find "${TMP_ARCHIVE_DIR}" -name "*.tar"`
if [ ! -f ${ARCHIVE_TMP_NAME} ]; then
    error_exit "Archive not found"
fi

# Manually add app/bootstrap.php.cache that was created by composer
tar -rf "${ARCHIVE_TMP_NAME}" app/bootstrap.php.cache
if [ $? -ne "0" ]; then
    error_exit "Could not add app/bootstrap.php.cache to tar"
fi

bzip2 -9 "${ARCHIVE_TMP_NAME}"
if [ $? -ne "0" ]; then
    error_exit "bzip2 failed"
fi

mv ${ARCHIVE_TMP_NAME}.bz2 ${CWD}/${NAME}.tar.bz2

#echo ${TMP_ARCHIVE_DIR}
rm -r ${TMP_ARCHIVE_DIR}

cd ${CWD}

echo "Created: ${CWD}/${NAME}.tar.bz2"
