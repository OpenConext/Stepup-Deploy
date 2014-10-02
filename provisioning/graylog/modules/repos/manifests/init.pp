class repos {
  exec { "aptgetupdate":
    command => "/usr/bin/apt-get update > /dev/null",
  }
}
