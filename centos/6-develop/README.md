## 6-develop

### Overview

Dockerfile to create a Docker image based on the latest CentOS 6 32/64-bits, plus selected development tools.

### Changes

Use `yum` to install a minimal set of existing CentOS development tools; as old as they are, they should be enough to build newer versions of the bootstrap tools.

### Developer

#### Create

To create the Docker image locally, use:

```console
$ cd ...
$ docker build --squash --tag "ilegeul/centos:6-develop-v1" -f Dockerfile-v1 .
$ docker build --squash --tag "ilegeul/centos32:6-develop-v1" -f Dockerfile32-v1 .
```

On macOS, to prevent entering sleep, use:

```console
$ caffeinate docker build --squash --tag "ilegeul/centos:6-develop-v1" -f Dockerfile-v1 .
$ caffeinate docker build --squash --tag "ilegeul/centos32:6-develop-v1" -f Dockerfile32-v1 .
```

#### Test

To test the image:

```console
$ docker run --interactive --tty ilegeul/centos:6-develop-v1
$ docker run --interactive --tty ilegeul/centos32:6-develop-v1
```

#### Publish

To publish, use:

```console
$ docker push "ilegeul/centos:6-develop-v1"
$ docker push "ilegeul/centos32:6-develop-v1"
```

#### Copy & Paste

```bash
caffeinate docker build --squash --tag "ilegeul/centos:6-develop-v1" -f Dockerfile-v1 .
docker push "ilegeul/centos:6-develop-v1"
caffeinate docker build --squash --tag "ilegeul/centos32:6-develop-v1" -f Dockerfile32-v1 .
docker push "ilegeul/centos32:6-develop-v1"

```

