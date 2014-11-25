#!/bin/bash

CWD=`pwd`
REPO=$1
if [ -z "${REPO}"  ]; then
    echo "Usage: $0 <repo>"
    echo "Repo's: Stepup-Deploy Stepup-Middleware Stepup-Gateway Stepup-SelfService Stepup-RA"
    exit 1;
fi


if [ ! -d "$REPO" ]; then
    cd ${CWD}
    git clone git@github.com:SURFnet/${REPO}.git
else
    cd ${CWD}/${REPO}
    git pull
fi

cd ${CWD}/${REPO}
COMMIT_HASH=`git log -1 --pretty="%H"`
COMMIT_DATE=`git log -1 --pretty="%cd" --date=iso`
COMMIT_Z_DATE=`php -r "echo gmdate('YmdHis\Z', strtotime('${COMMIT_DATE}'));"`
COMMIT_BRANCH=`git rev-parse --abbrev-ref HEAD`
NAME=${REPO}-${COMMIT_BRANCH}-${COMMIT_Z_DATE}-${COMMIT_HASH}

export SYMPHONY_ENV=prod
composer.phar install --prefer-dist --ignore-platform-reqs --no-dev --no-interaction --optimize-autoloader
if [ $? -ne "0" ]; then
    echo "Composer install failed"
    exit 1;
fi

TMP_ARCHIVE_DIR=`mktemp -d "/tmp/${REPO}.XXXXXXXX"`
if [ $? -ne "0" ]; then
    echo "Could not create temp dir"
    exit 1;
fi

composer.phar archive --format=tar --dir="${TMP_ARCHIVE_DIR}" --no-interaction
if [ $? -ne "0" ]; then
    echo "Composer achive failed"
    rm -r ${TMP_ARCHIVE_DIR}
    exit 1;
fi

ARCHIVE_TMP_NAME=`find "${TMP_ARCHIVE_DIR}" -name "*.tar"`
bzip2 -9 "${ARCHIVE_TMP_NAME}"
mv ${ARCHIVE_TMP_NAME}.bz2 ${CWD}/${NAME}.tar.bz2

rm -r ${TMP_ARCHIVE_DIR}

cd ${CWD}
