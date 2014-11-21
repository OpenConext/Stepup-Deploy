#!/bin/bash

# Add input to Graylog via RPC
# Connects to 127.0.0.1


IP_ADDRESS=127.0.0.1
GRAYLOG2_ROOT_USER=$1
GRAYLOG2_ROOT_PASSWORD=$2

if [ -z "${GRAYLOG2_ROOT_USER}" -o -z "${GRAYLOG2_ROOT_PASSWORD}" ]; then
   echo "Usage $0 <user> <password>"
   exit 1
fi

GRAYLOG2_URL="http://${GRAYLOG2_ROOT_USER}:${GRAYLOG2_ROOT_PASSWORD}@${IP_ADDRESS}:12900"
GRAYLOG2_INPUT_SYSLOG_UDP="{
  \"global\": \"true\",
  \"title\": \"Syslog UDP\",
  \"configuration\": {
    \"port\": 1514,
    \"bind_address\": \"0.0.0.0\"
  },
  \"creator_user_id\": \"${GRAYLOG2_ROOT_USER}\",
  \"type\": \"org.graylog2.inputs.syslog.udp.SyslogUDPInput\" }"

# List available inputs
echo -n "Listing inputs... "
INPUTS=`/usr/bin/curl -s -X GET -H "Content-Type: application/json" ${GRAYLOG2_URL}/system/inputs 2>/dev/null`
if [ $? != "0" ]; then
    echo "Could not get current inputs. REST call to Graylog2 failed"
    exit 1
fi
echo "OK"


# Add input only when it does not exist yet (match on "title" specified while adding input)
if [ `echo $INPUTS | grep -c '"title":"Syslog UDP"'` != "1" ]; then
    echo -n "Adding input... "
    echo $CURL_PARAM
    NEW_INPUT=`/usr/bin/curl -s -X POST -H "Content-Type: application/json" -d "${GRAYLOG2_INPUT_SYSLOG_UDP}" ${GRAYLOG2_URL}/system/inputs/`
    if [ $? != "0" ]; then
        echo "Could not add inputs. REST call to Graylog2 failed"
        exit 1
    fi
    # Result should be something like: {"persist_id":"546f447ae4b0e4fe2aaaadf3","input_id":"3990f28a-e08b-4733-97af-0b7fcaa36be7"}
    if [ `echo $NEW_INPUT | grep -c '"input_id":'` != "1" ]; then
        echo "Adding input failed"
        echo ${NEW_INPUT}
        exit 1
    fi

    echo "OK"
else
    echo "Input exists. Nothing to do"
fi

exit 0