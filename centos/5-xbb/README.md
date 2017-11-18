## 5-xbb

### Overview

Dockerfile to create a Docker image based on the latest CentOS 5 64-bits development image, plus selected new tools.

### Changes

Using the bootstrap development tools, build final newer versions of the tools from sources. 

This step installs the newly created tools in `/opt/xbb`, using several temporary folders.

To use the bootstrap tools, add `/opt/xpp-bootstrap/bin` to the path:

```console
$ source /opt/xbb/xbb.sh
$ xbb_activate
```

### Developer

To create the Docker image locally, use:

```console
$ cd ...
$ docker build --tag "ilegeul/centos:5-xbb" -f Dockerfile .
```

On macOS, to prevent entering sleep, use:

```console
$ caffeinate docker build --tag "ilegeul/centos:5-xbb" -f Dockerfile .
```

To test the image:

```console
$ docker run --interactive --tty ilegeul/centos:5-xbb
```

To create a second version:

```console
$ caffeinate docker build --tag "ilegeul/centos:5-xbb-v2" -f Dockerfile-v2 .
```

To publish, use:

```console
$ docker push "ilegeul/centos:5-xbb"
```
