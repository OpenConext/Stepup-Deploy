#!/usr/bin/env bash

# Specify where we will install
# the certificate
SSL_DIR="ssl"

# Set the wildcarded domain
# we want to use
DOMAIN="*.stepup.coin.surf.net"

# A blank passphrase
PASSPHRASE=""

# Set our CSR variables
SUBJ="
C=NL
ST=
O=
localityName=Utrecht
commonName=$DOMAIN
organizationalUnitName=
emailAddress=support@ibuildings.nl
"

# Create our SSL directory
# in case it doesn't exist
sudo mkdir -p "$SSL_DIR"

# Generate our Private Key, CSR and Certificate
sudo openssl genrsa -out "$SSL_DIR/server.key" 2048
sudo openssl req -new -subj "$(echo -n "$SUBJ" | tr "\n" "/")" -key "$SSL_DIR/server.key" -out "$SSL_DIR/server.csr" -passin pass:$PASSPHRASE
sudo openssl x509 -req -days 365 -in "$SSL_DIR/server.csr" -signkey "$SSL_DIR/server.key" -out "$SSL_DIR/server.crt"
sudo cp "$SSL_DIR/server.crt" "$SSL_DIR/ca.crt"
