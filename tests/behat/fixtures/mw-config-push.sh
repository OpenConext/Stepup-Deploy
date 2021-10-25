#!/bin/bash

CWD=`pwd`

function error_exit {
    echo "${1}"
    if [ -n "${TMP_FILE}" -a -d "${TMP_FILE}" ]; then
        rm "${TMP_FILE}"
    fi
    cd ${CWD}
    exit 1
}

# Script to write the middleware config

TMP_FILE=`mktemp -t midcfg.XXXXXX`
if [ $? -ne "0" ]; then
    error_exit "Could not create temp file"
fi

echo "Pushing new config to: http://middleware.stepup.example.com/management/configuration"

http_response=`curl --write-out %{http_code} --output ${TMP_FILE} -XPOST -s \
    -u management:secret \
    -H "Accept: application/json" \
    -H "Content-type: application/json" \
    --cookie "testcookie=testcookie" \
    -d @./fixtures/mw-config.json \
    http://middleware.stepup.example.com/management/configuration`

output=`cat ${TMP_FILE}`
rm ${TMP_FILE}
echo $output

res=$?
if [ $res -ne "0" ]; then
    error_exit "Curl failed with code $res"
fi

# Check for HTTP 200
if [ "${http_response}" -ne "200" ]; then
    error_exit "Unexpected HTTP response: ${http_response}"
fi

# On success JSON output should start with: {"status":"OK"
ok_count=`echo "${output}" | grep -c "status"`
if [ $ok_count -ne "1" ]; then
    error_exit "Expected one JSON \"status: OK\" in response, found $ok_count"
fi

echo "OK. New config pushed"