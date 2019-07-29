#!/usr/bin/env bash

# Copyright 2019 SURFnet B.V.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Check required tools
JQ=`which jq`
if [ $? -ne 0 ]; then
  echo "Error: 'jq' (https://stedolan.github.io/jq/) is required but could not be found in the current path."
  exit 1
fi
CURL=`which curl`
if [ $? -ne 0 ]; then
  echo "Error: 'curl' (https://curl.haxx.se/) is required but could not be found in the current path."
  exit 1
fi


# Get directory where script this script is located
basedir="$(CDPATH= cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Config file with manage credentials and locations
config=~/.manage.config

if [ $# -lt 2 ]; then
    echo "Retrieves the metadata of a SAML service provider from OpenConext-Manage and"
    echo "converts it to JSON for use in OpenConext Stepup-Middleware configuration."
    echo
    echo "Usage ${0##*/} <environment name> <entityid>"
    echo
    echo "<environment name> : The name of the environment as defined in ~/.manage.config"
    echo "<entityid>         : The EntityID of the service provider in OpenConext-Manage"
    exit 1
fi

# Get configuration
if [ ! -f ${config} ]; then
    echo "Error: Configuration file '${config}' not found."
    echo
    echo 'Example ~/.manage.config:'
    echo '{'
    echo '  "prod": {'
    echo '    "url": "https://manage.example.org/manage/api/internal/search/saml20_sp",'
    echo '    "login": "ro_user",'
    echo '    "password": "secret"'
    echo '  }'
    echo '}'
    exit 1
fi

environment=$1

${JQ} -e ".|has(\"${environment}\")" ~/.manage.config > /dev/null
if [ $? -ne 0 ]; then
  echo "Error: Could not find definition for environment '${environment}' in ~/.manage.config"
  exit 1
fi
manage_url=`${JQ} -r ".\"${environment}\".url" ~/.manage.config`
manage_login=`${JQ} -r ".\"${environment}\".login" ~/.manage.config`
manage_password=`${JQ} -r ".\"${environment}\".password" ~/.manage.config`


entityid=$2

# Send query to manage
# --fail: non zero exit code on HTTP status >= 400
# --silent: suppress showing transfer/progress
# --show-error: do not suppress errors when running --silent
response=`${CURL} --fail --silent --show-error \
                  -H 'Content-Type: application/json' \
                  -u ${manage_login}:${manage_password} \
                  -X POST \
                  -d "{\"entityid\":\"${entityid}\",\"ALL_ATTRIBUTES\":true}" \
                  ${manage_url}`
if [ $? -ne 0 ]; then
   echo "ERROR: POST to '${manage_url}' failed"
   exit 1
fi
echo ${response}
echo ${response} | ${JQ} -f ${basedir}/middleware-config-from-manage.jq | sed 's/\\r\\n//g' 
if [ $? -ne 0 ]; then
   echo "ERROR: Parsing manage response failed"
   exit 1
fi
