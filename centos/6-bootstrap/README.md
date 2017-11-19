## 6-bootstrap

### Overview

Dockerfile to create a Docker image based on the latest CentOS 6 64-bits development image, plus selected new tools.

### Changes

Using the original development tools, build newer versions of the tools from sources. 

Due to the limitations of the old GCC 4.4, they are not the final tools, but new enough to build a modern GCC, which will be used to build the final tools & libraries.

This step installs the newly created tools in `/opt/xbb-bootstrap`, using several temporary folders.

To use the bootstrap tools, add `/opt/xpp-bootstrap/bin` to the path:

```console
$ PATH=/opt/xbb-bootstrap/bin:$PATH
```

### Developer

To create the Docker image locally, use:

```console
$ cd ...
$ docker build --tag "ilegeul/centos:6-bootstrap" -f Dockerfile .
```

On macOS, to prevent entering sleep, use:

```console
$ caffeinate docker build --tag "ilegeul/centos:6-bootstrap" -f Dockerfile .
```

To test the image:

```console
$ docker run --interactive --tty ilegeul/centos:6-bootstrap
```

To create a second version:

```console
$ caffeinate docker build --tag "ilegeul/centos:6-bootstrap-v2" -f Dockerfile-v2 .
```

To publish, use:

```console
$ docker push "ilegeul/centos:6-bootstrap"
```
