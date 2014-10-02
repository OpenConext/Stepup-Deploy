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

```sh-session
$ mkdir suaas
$ cd suaas
$ mkdir middleware gateway selfservice ra
$ git clone git@github.com:SURFnet/Stepup-Deploy.git deploy
$ cd deploy
$ git checkout dev
$ git submodule update --init --recursive
$ vagrant plugin install vagrant-vbguest
$ (cd suaas && vagrant up)
$ (cd graylog && vagrant up)
```

Place the SSL certificates in `./ssl`:

 * `ca.crt` — CA certificate chain
 * `server.crt` — Server wildcard certificate
 * `server.key` — Server wildcard private key

Place the projects in their respective directories (middleware, gateway, etc.)

Edit your hosts file to include the following:

```
10.0.0.100  mw-dev.stepup.coin.surf.net gw-dev.stepup.coin.surf.net ss-dev.stepup.coin.surf.net ra-dev.stepup.coin.surf.net
10.0.0.101  g2-dev.stepup.coin.surf.net
```

Visit https://mw-dev.stepup.coin.surf.net.