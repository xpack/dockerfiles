## 6-tex

### Overview

Dockerfile to create a Docker image based on the latest CentOS 6 32/64-bits development image and TexLive.

### Changes

None.

To use the new tools, add `/opt/texlive/bin/<arch>` to the path.

### Developer

#### Create

To create the Docker image locally, use:

```console
$ cd ...
$ docker build --squash --tag "ilegeul/centos:6-tex-v1" -f Dockerfile-v1 .
$ docker build --squash --tag "ilegeul/centos32:6-tex-v1" -f Dockerfile32-v1 .
```

On macOS, to prevent entering sleep, use:

```console
$ caffeinate docker build --squash --tag "ilegeul/centos:6-tex-v1" -f Dockerfile-v1 .
$ caffeinate docker build --squash --tag "ilegeul/centos32:6-tex-v1" -f Dockerfile32-v1 .

$ caffeinate docker build --squash --tag "ilegeul/centos:6-tex-v1" -f Dockerfile-v1 .

```

To create a second, third, etc version:

```console
$ caffeinate docker build --squash --tag "ilegeul/centos:6-tex-v2" -f Dockerfile-v2 .
$ caffeinate docker build --squash --tag "ilegeul/centos:6-tex-v3" -f Dockerfile-v3 .
$ caffeinate docker build --squash --tag "ilegeul/centos32:6-tex-v2" -f Dockerfile32-v2 .
$ caffeinate docker build --squash --tag "ilegeul/centos32:6-tex-v3" -f Dockerfile32-v3 .
```

#### Test

To test the image:

```console
$ docker run --interactive --tty ilegeul/centos:6-tex-v1
$ docker run --interactive --tty ilegeul/centos:6-tex-v2
$ docker run --interactive --tty ilegeul/centos32:6-tex-v1
$ docker run --interactive --tty ilegeul/centos32:6-tex-v2
```

#### Publish

To publish, use:

```console
$ docker push "ilegeul/centos:6-tex-v1"
$ docker push "ilegeul/centos32:6-tex-v1"
```

#### Copy & Paste

```bash
caffeinate docker build --squash --tag "ilegeul/centos:6-tex-v1" -f Dockerfile-v1 .
docker push "ilegeul/centos:6-tex-v1"
caffeinate docker build --squash --tag "ilegeul/centos32:6-tex-v1" -f Dockerfile32-v1 .
docker push "ilegeul/centos32:6-tex-v1"

```
