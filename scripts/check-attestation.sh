#!/bin/bash
if [ $# -eq 0 ]
then
    echo "Usage: $0 <yk-attestation.cer>"
    exit 1
fi
# Download Yubico root certificates
wget https://developers.yubico.com/U2F/yubico-u2f-ca-certs.txt -O yubico-u2f-ca-certs.txt -q

# Check fingerprint of root
CHECK=`openssl x509 -in yubico-u2f-ca-certs.txt -noout -fingerprint -sha256`
if [ "$CHECK" != "SHA256 Fingerprint=0F:A1:38:6F:80:EB:87:13:26:3A:E5:C1:D8:4D:EB:45:5B:DF:08:AE:A5:0A:B0:55:03:CE:FE:E8:2B:09:2D:42" ] 
then
	echo "yubico-u2f-ca-certs.txt fingerptint failed"
	exit 2
fi

# Verify the certificate
openssl verify -CAfile ./yubico-u2f-ca-certs.txt $1
rm yubico-u2f-ca-certs.txt



