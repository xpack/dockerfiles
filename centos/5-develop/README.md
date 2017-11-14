## 5-develop

### Overview

Dockerfile to create a Docker image based on the latest CentOS 5 64-bits, plus selected development tools.

### Changes

Use `yum` to install a minimal set of existing CentOS development tools; as old as they are, they should be enough to build newer versions of the bootstrap tools.

### Developer

To create the Docker image, use:

```console
$ docker build --tag "ilegeul/centos:5-develop" \
https://github.com/ilg-ul/docker/raw/master/centos/5-develop/Dockerfile
```

To create the Docker image locally, use:

```console
$ cd ...
$ docker build --tag "ilegeul/centos:5-develop" .
```

On macOS, to prevent entering sleep, use:

```console
$ caffeinate docker build --tag "ilegeul/centos:5-develop" .
```

To publish, use:

```console
$ docker push "ilegeul/centos:5-develop"
```

