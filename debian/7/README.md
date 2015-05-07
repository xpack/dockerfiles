Dockerfile to create a Docker image to be used as Debian 7 64-bit base.

Prerequisites:

	sudo apt-get update
	sudo apt-get upgrade
	sudo apt-get install debootstrap

To create the new image use:

	mkdir docker
	cd docker
	git clone https://github.com/docker/docker.git docker.git
	sudo docker.git/contrib/mkimage.sh -d . debootstrap --variant=minbase --components=main --include=inetutils-ping,iproute \
    	wheezy http://httpredir.debian.org/debian



