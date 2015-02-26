#!/bin/bash

# Generate a self signed certificate and private key
# Certificate DN: CN=<Descriptive name>

# If a keyczar directory is provided, the key is output encrypted as well.

if [ $# -lt 1 ]; then
    echo "Usage $0 <Descriptive name> [keyvault for encrypting private key]"
    exit 1
fi

tmpdir=`mktemp -d -t sscrt`

# Generate RSA private key with 2048 bit modulus
openssl genrsa -out ${tmpdir}/private_key.pem 2048 -nodes

# Create certificate signing request
openssl req -new -key ${tmpdir}/private_key.pem -out ${tmpdir}/csr.pem -subj "/CN=$1"

# Create self signed certificate valid for 10ish years
openssl x509 -req -days 3650 -in ${tmpdir}/csr.pem -signkey ${tmpdir}/private_key.pem -out ${tmpdir}/certificate.pem


cat ${tmpdir}/private_key.pem

cat ${tmpdir}/certificate.pem

if [ -d "$2" ]; then
    `dirname $0`/encrypt-file.sh "$2" -f "${tmpdir}/private_key.pem"
fi
  

rm -r ${tmpdir}

