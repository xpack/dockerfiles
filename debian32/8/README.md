Dockerfile to create a Docker image to be used as Debian 8 32-bits base.

Prerequisites:

A running minimal Debian 8 32-bits system, with:

	sudo apt-get update
	sudo apt-get upgrade
	sudo apt-get install git debootstrap

To create the rootfs.tar.xz archive, use:

	mkdir docker
	cd docker
	git clone https://github.com/docker/docker.git docker.git
	sudo docker.git/contrib/mkimage.sh -d . debootstrap \
		--variant=minbase --components=main \
		--include=inetutils-ping,iproute \
    	jessie http://httpredir.debian.org/debian

To create the Docker image, use:

	git clone https://github.com/ilg-ul/docker.git docker.git
	cd docker.git/debian32/8
	docker build --tag "ilegeul/debian32:8" .

To publish the Docker image on [Docker Hub](https://hub.docker.com/u/ilegeul/), use:

	docker push ilegeul/debian32:8

