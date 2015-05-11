Dockerfile to create a Docker image to be used as Debian 7 64-bits base.

Prerequisites:

	sudo apt-get update
	sudo apt-get upgrade
	sudo apt-get install debootstrap

To create the rootfs.tar.xz archive, use:

	mkdir docker
	cd docker
	git clone https://github.com/docker/docker.git docker.git
	sudo docker.git/contrib/mkimage.sh -d . debootstrap --variant=minbase --components=main --include=inetutils-ping,iproute \
    	wheezy http://httpredir.debian.org/debian

To create the Docker image, use:

	git clone https://github.com/ilg-ul/docker.git docker.git
	cd docker.git/debian/7
	docker build --tag "ilegeul/debian:7" .

To publish the Docker image on [Docker Hub](https://hub.docker.com/u/ilegeul/), use:

	docker push ilegeul/debian:7

