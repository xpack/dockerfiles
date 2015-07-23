Dockerfile to create a Docker image to be used for QEMU Windows builds.

It is based on a Debian 8 64-bits GCC with mingw-w64 packages, plus the packages created by [Stefan Weil](http://qemu.weilnetz.de/debian/).

To create the Docker image, use:

	docker build --tag "ilegeul/debian:8-gnuarm-mingw-gtk" \
	https://github.com/ilg-ul/docker/raw/master/debian/8-gnuarm-mingw-gtk/Dockerfile

To create the Docker image locally, use:

	cd ...
	docker build --tag "ilegeul/debian:8-gnuarm-mingw-gtk" .
