#!/bin/bash

# Generate a plaintext password

# If a keyczar directory is provided, the password is output encrypted as well.

if [ $# -lt 1 ]; then
    echo "Usage $0 <password length in characters> [keyvault for encrypting private key]"
    exit 1
fi

password=`env LC_CTYPE=C LC_ALL=C tr -dc "a-zA-Z0-9-_\$\?" < /dev/urandom | head -c $1`

if [ -d "$2" ]; then
    tempfile=`mktemp -t genpass`
    echo ${password} > "$tempfile"    
    `dirname $0`/encrypt-file.sh "$2" -f "$tempfile"
    cat "$tempfile"
    rm "$tempfile"
else
    echo $password
fi
  


