## 6-bootstrap

### Overview

Dockerfile to create a Docker image based on the latest CentOS 6 32/64-bits development image, plus selected new tools.

### Changes

Using the original development tools, build newer versions of the tools from sources. 

Due to the limitations of the old GCC 4.4, they are not the final tools, but new enough to build a modern GCC, which will be used to build the final tools & libraries.

This step installs the newly created tools in `/opt/xbb-bootstrap`, using several temporary folders.

To use the bootstrap tools, add `/opt/xpp-bootstrap/bin` to the path:

```console
$ PATH=/opt/xbb-bootstrap/bin:$PATH
```

### Developer

#### Create

To create the Docker image locally, use:

```console
$ cd ...
$ docker build --squash --tag "ilegeul/centos:6-bootstrap-v1" -f Dockerfile-v1 .
$ docker build --squash --tag "ilegeul/centos32:6-bootstrap-v1" -f Dockerfile32-v1 .
```

On macOS, to prevent entering sleep, use:

```console
$ caffeinate docker build --squash --tag "ilegeul/centos:6-bootstrap-v1" -f Dockerfile-v1 .
$ caffeinate docker build --squash --tag "ilegeul/centos32:6-bootstrap-v1" -f Dockerfile32-v1 .
```

To create a second version:

```console
$ caffeinate docker build --squash --tag "ilegeul/centos:6-bootstrap-v2" -f Dockerfile-v2 .
$ caffeinate docker build --squash --tag "ilegeul/centos32:6-bootstrap-v2" -f Dockerfile32-v2 .
```

#### Test

To test the images:

```console
$ docker run --interactive --tty ilegeul/centos:6-bootstrap-v1
$ docker run --interactive --tty ilegeul/centos32:6-bootstrap-v1
```

#### Publish

To publish, use:

```console
$ docker push "ilegeul/centos:6-bootstrap-v1"
$ docker push "ilegeul/centos32:6-bootstrap-v1"
```
