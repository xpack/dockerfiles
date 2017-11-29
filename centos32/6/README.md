## Dockerfile to create a Docker image to be used as CentOS 6 32-bits base.

### Download CentOS 6.9 ISO

Download `CentOS-6.9-i386-bin-DVD1` from one of the existing mirrors listed in
[Download](https://wiki.centos.org/Download), for example from:

http://centos.mirrors.telekom.ro/6.9/isos/i386/

Note: do not use the `netinstall` image, it fails shortly after booting.

### Install as a VM

Install a desktop packages group.

### Make the base image

```console
$ wget https://github.com/moby/moby/raw/master/contrib/mkimage-yum.sh
$ vi mkimage-yum.sh
tar cJf /tmp/rootfs.tar.xz --numeric-owner --auto-compress -C "$target" --transform=s,^./,, .

$ sudo bash mkimage-yum.sh xyz
```

Copy `/tmp/rootfs.tar.xz` to the Docker machine.

```console
$ scp 172.16.62.43:/tmp/rootfs.tar.xz .
```

### Build

```console
$ docker build --squash --tag "ilegeul/centos32:6" .
```

### Publish

To publish the Docker image on [Docker Hub](https://hub.docker.com/u/ilegeul/), use:

```console
$ docker push ilegeul/centos32:6
```

