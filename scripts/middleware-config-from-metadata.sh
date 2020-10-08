#!/usr/bin/env bash

# Copyright 2018 SURFnet B.V.
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

# Generate middleware-config entry from SAML metadata

BASEDIR=`dirname $0`

metadataurl="$1"
if [ -z "${metadataurl}"  ]; then
    echo "Usage $0 <metadata URL>"
    exit 1;
fi

tmpfile=$(mktemp mw-from-meta.XXXXXX)
rv=$?
if [ $rv -ne 0 ]; then
  echo "Error creating temporary file"
  exit $rv
fi

# Download metadata using curl
# --fail makes curl return a non zero exit code when the server return a non 2xx HTTP response
curl --fail "${metadataurl}" > "${tmpfile}"
rv=$?
if [ $rv -ne 0 ]; then
  echo "Error downloading metadata"
  rm "$tmpfile"
  exit 1
fi

xsltproc ${BASEDIR}/middleware-config-from-metadata.xslt "${tmpfile}"
rv=$?
if [ $rv -ne 0 ]; then
  echo "Error processing metadata"
fi

rm "$tmpfile"
exit $rv

