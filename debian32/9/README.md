Dockerfile to create a Docker image to be used as Debian 9 32-bits base.

Prerequisites:

A running minimal Debian 9 32-bits system. For this:

Download the installation image from [Getting Debian](https://cdimage.debian.org/debian-cd/current/i386/iso-cd/debian-9.0.0-i386-netinst.iso)

Install, possibly in a virtual machine.

Run:

```bash
$ sudo apt-get update
$ sudo apt-get upgrade
$ sudo apt-get -y install git debootstrap curl
```

To create the rootfs.tar.xz archive, use:

```bash
$ mkdir docker
$ cd docker
$ git clone https://github.com/moby/moby.git moby.git
$ sudo moby.git/contrib/mkimage.sh -d . debootstrap \
	--variant=minbase --components=main \
	--include=inetutils-ping,iproute \
    stretch http://httpredir.debian.org/debian
```

The current moby.git commit is 7117d5ef25b54c3384fbaf5cf279e0dcc6701a52.

The `mkimage.sh` script downloads again some of the original packages from 
the server, but it still needs to run in a 32-bits machine. It is not clear 
how much of the environment is used.

Copy the file outside the Debian virtual machine, for example with scp.

To create the Docker image, use:

```bash
$ git clone https://github.com/ilg-ul/docker.git docker.git
$ cd docker.git/debian32/9
$ docker build --tag "ilegeul/debian32:9" .
```

The same thing locally:

```bash
$ cd docker.git/debian32/9
$ docker build --tag "ilegeul/debian32:9" .
```

To publish the Docker image on [Docker Hub](https://hub.docker.com/u/ilegeul/), use:

```bash
$ docker push ilegeul/debian32:9
```

