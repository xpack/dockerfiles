## 5-bootstrap

### Overview

Dockerfile to create a Docker image based on the latest CentOS 5 64-bits development image, plus selected new tools.

### Changes

Using the original development tools, build newer versions of the tools from sources. 

Due to the limitations of the GCC 4.1, they are not the final tools, but a new enough to build a modern GCC, which will be used to build the final tools & libraries.

The script builds:

- a newer openssl
- a newer curl, based on the new openssl, required to download the source archives
- newer versions of
    - m4
    - autoconf
    - automake
    - libtool
    - pkg_config

Since access to the current download sites requires https, and the old `curl` does not know it, the `openssl` and `curl` archives are provided directly to the script.
 

### Developer

To create the Docker image, use:

```console
$ docker build --tag "ilegeul/centos:5-bootstrap" \
https://github.com/ilg-ul/docker/raw/master/centos/5-bootstrap/Dockerfile
```

To create the Docker image locally, use:

```console
$ cd ...
$ docker build --tag "ilegeul/centos:5-bootstrap" .
```

On macOS, to prevent entering sleep, use:

```console
$ caffeinate docker build --tag "ilegeul/centos:5-bootstrap" .
```

To publish, use:

```console
$ docker push "ilegeul/centos:5-bootstrap"
```

