Dockerfile to create a Docker image to be used for QEMU Windows builds.

It is based on a Debian 8 64-bits (actually the GNU ARM GCC image), plus lots of mingw-w64 packages.

It also includes the packages created by [Stefan Weil](http://qemu.weilnetz.de/debian/).

To create the Docker image, use:

	docker build --tag "ilegeul/debian:8-gnuarm-mingw" \
	https://github.com/ilg-ul/docker/raw/master/debian/8-gnuarm-mingw/Dockerfile
