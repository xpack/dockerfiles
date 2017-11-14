### 5-final

### Overview

Dockerfile to create a Docker image based on a CentOS 5 64-bits, plus the final available updates.

### Changes

Since this version reached end of life in March 2017, the mirrors are no longer active and the packages are only available from the vault, thus the `sed` line used to update the `baseurl`.

The `rpm --import` line is used to avoid an warning during update.

The `downgrade` is used to avoid an error, probably caused by a wrong dependency.

### Developer

To create the Docker image, use:

```console
$ docker build --tag "ilegeul/centos:5-final" \
https://github.com/ilg-ul/docker/raw/master/centos/5-final/Dockerfile
```

To create the Docker image locally, use:

```console
$ cd ...
$ docker build --tag "ilegeul/centos:5-final" .
```

On macOS, to prevent entering sleep, use:

```console
$ caffeinate docker build --tag "ilegeul/centos:5-final" .
```

To publish, use:

```console
$ docker push "ilegeul/centos:5-final"
```

