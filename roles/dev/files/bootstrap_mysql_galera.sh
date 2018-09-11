#!/bin/bash

# Bootstrap mysql Galera cluster.
# A mysql server that is part of a cluster will start unless it can see another node in the same cluser.
# This means that "service mysql start" will fail if it is the only node in a cluster.

# The first node must be explicitly bootstrapped.
# This can be done by starting it with the "bootstrap" instead of the "start"

# Bootstrap the server. This will start a new cluster. The data in the database is kept.

service mysql bootstrap