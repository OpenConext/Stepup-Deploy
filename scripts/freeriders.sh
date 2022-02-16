#!/usr/bin/env bash

# Check required tools
JQ=$(which jq)
if [ $? -ne 0 ]; then
  echo "Error: 'jq' (https://stedolan.github.io/jq/) is required but could not be found in the current path."
  exit 1
fi
CURL=$(which curl)
if [ $? -ne 0 ]; then
  echo "Error: 'curl' (https://curl.haxx.se/) is required but could not be found in the current path."
  exit 1
fi

# Get directory where script this script is located
basedir="$(CDPATH= cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Config file with manage credentials and locations
config=~/.manage.config

if [ $# -lt 2 ]; then
    echo "Retrieves a list of all known values for schachome of SURFconext connexted IdP's"
    echo "and compares it to the middleware whitelist configuration."
    echo "The output is an ansible list to add to stepup-middleware.yml"
    echo
    echo "Usage ${0##*/} <environment name> <ssid-enviroment-location>"
    echo
    echo "<environment name> : The name of the environment as defined in ~/.manage.config"
    echo "<ssid-enviroment-location>: the full path to the ansible inventory for the ssid enviroment, e.g. '~/Stepup/Stepup-Deploy-SURFnet/test/'"
    exit 1
fi

# Get configuration
if [ ! -f ${config} ]; then
    echo "Error: Configuration file '${config}' not found."
    echo
    echo 'Example ~/.manage.config:'
    echo '{'
    echo '  "prod-idp": {'
    echo '    "url": "https://manage.example.org/manage/api/internal/search/saml20_idp",'
    echo '    "login": "ro_user",'
    echo '    "password": "secret"'
    echo '  }'
    echo '}'
    exit 1
fi

environment=$1
ssidenvironment=$2

${JQ} -e ".|has(\"${environment}\")" ~/.manage.config > /dev/null
if [ $? -ne 0 ]; then
  echo "Error: Could not find definition for environment '${environment}' in ~/.manage.config"
  exit 1
fi
manage_url=$(${JQ} -r ".\"${environment}\".url" ~/.manage.config)
manage_login=$(${JQ} -r ".\"${environment}\".login" ~/.manage.config)
manage_password=$(${JQ} -r ".\"${environment}\".password" ~/.manage.config)

manage_url=`echo "$manage_url" | sed 's/saml20_sp/saml20_idp/g'`

entityid=$2

# Send query to manage
# --fail: non zero exit code on HTTP status >= 400
# --silent: suppress showing transfer/progress
# --show-error: do not suppress errors when running --silent
response=$(${CURL} --fail --silent --show-error \
                  -H 'Content-Type: application/json' \
                  -u "${manage_login}:${manage_password}" \
                  -X POST \
                  -d "{\"metaDataFields.shibmd:scope:0:allowed\":\".*\",\"REQUESTED_ATTRIBUTES\":[\"metaDataFields.shibmd:scope:0:allowed\"],\"LOGICAL_OPERATOR_IS_AND\":true}" \
                  "${manage_url}")
if [ $? -ne 0 ]; then
   echo "ERROR: POST to '${manage_url}' failed"
   exit 1
fi
echo "freeriders:"
echo "${response}" | jq -r '.[] | .data.metaDataFields."shibmd:scope:0:allowed"' | sort | uniq | while read line; 
do 
	if ! grep -q "$line" "$ssidenvironment"/templates/middleware/middleware-whitelist.json.j2; then echo "    - $line"; fi
done