# SuaaS development boxes

## Boxes

 * `suaas` — Apache2, PHP-FPM, MariaDB and virtual hosts for Middleware, Gateway, Self-Service and RA;
 * `graylog` — Graylog2 server and web interface.

## Requirements

 * VirtualBox (tested with 4.3.16)
 * Vagrant (tested with 1.6.3)
 * Vagrant vbguest plugin (instructions below)
 * Ansible (tested with 1.7.2), fallback to self-provisioning on Windows (untested)

## Installation

This setup is designed to run next to the four step-up applications Middleware, Gateway, Self-Service and RA:

 * `Stepup-Deploy/` — Contains the application and Graylog2 boxes
 * `Stepup-Middleware/` — Contains the Middleware application code
 * `Stepup-Gateway/` — Contains the Gateway application code
 * `Stepup-SelfService/` — Contains the Self-Service application code
 * `Stepup-RA/` — Contains the RA application code

```sh-session
$ mkdir suaas
$ cd suaas
$ git clone git@github.com:SURFnet/Stepup-Deploy.git
$ git clone git@github.com:SURFnet/Stepup-Middleware.git
$ git clone git@github.com:SURFnet/Stepup-Gateway.git
$ git clone git@github.com:SURFnet/Stepup-SelfService.git
$ git clone git@github.com:SURFnet/Stepup-RA.git
$ mkdir simplesamlphp # Place a simplesamlphp deployment here with some credentials, set baseurlpath to "/"
$ cd Stepup-Deploy
$ (cd ssl && place-ssl-certificates-see-below)
$ git checkout dev
$ git submodule update --init --recursive
$ vagrant plugin install vagrant-vbguest
$ (cd suaas && vagrant up)
$ (cd graylog && vagrant up)
```

Place the SSL certificates in `./Stepup-Deploy/ssl`:

 * `ca.crt` — CA certificate chain
 * `server.crt` — Server wildcard certificate
 * `server.key` — Server wildcard private key

Edit your hosts file to include the following:

```
10.10.0.100  mw-dev.stepup.coin.surf.net gw-dev.stepup.coin.surf.net ss-dev.stepup.coin.surf.net ra-dev.stepup.coin.surf.net idp-dev.stepup.coin.surf.net
10.10.0.101  g2-dev.stepup.coin.surf.net
```

 * To view the self-service, visit https://ss-dev.stepup.coin.surf.net/app_dev.php/.
 * To view the Graylog2 web interface, vist http://g2-dev.stepup.coin.surf.net:9000 and use username `admin` and password `yourpassword`.
