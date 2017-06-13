SSL development certificates
----------------------------

The Stepup development VM uses a SSL certificate signed with a local
CA, for development purposes only. In order to make all internal SSL
requests validate out-of-the-box (e.g. selfservice preforming a
request over https to middleware) this CA is added to the CentOS
trusted CA keystore.

Developers should trust this local CA once in their browser on first
visit to a Stepup application.

The ansible 'web' role (web/tasks/main.yml specifically) is
responsible for configuring nginx and the CA keystore.

For future reference, the following openssl commands were used to
generate the certificates:

1. Generate local CA private key

    openssl genrsa -aes256 -out ca.key 8192
    > pass: surf
    
2. Generate the CA certificate

    openssl req -new -x509 -extensions v3_ca -key ca.key -out ca.crt -days 3650
    > Country Name (2 letter code) [AU]:NL
    > State or Province Name (full name) [Some-State]:Utrecht
    > Locality Name (eg, city) []:Utrecht
    > Organization Name (eg, company) [Internet Widgits Pty Ltd]:SURFnet B.V.
    > Organizational Unit Name (eg, section) []:
    > Common Name (e.g. server FQDN or YOUR name) []:SURFnet B.V.
    
Generating a key for 10 years is usually a bad idea, but fine for our purposes.

3. Generate the SSL server certificate

    openssl genrsa -des3 -out server.key 4096
    > Pass: surf

    openssl req -new -key server.key -out server.csr
    > Country Name (2 letter code) [AU]:NL
    > State or Province Name (full name) [Some-State]:Utrecht 
    > Locality Name (eg, city) []:Utrecht
    > Organization Name (eg, company) [Internet Widgits Pty Ltd]:SURfnet B.V.
    > Organizational Unit Name (eg, section) []:
    > Common Name (e.g. server FQDN or YOUR name) []:*.stepup.coin.surf.net
    > Email Address []:

    > Please enter the following 'extra' attributes
    > to be sent with your certificate request
    > A challenge password []:
    > An optional company name []:

4. Sign the SSL server certificate

    openssl x509 -req -days 3650 -in server.csr -CA ca.crt -CAkey ca.key -set_serial 01 -out server.crt
