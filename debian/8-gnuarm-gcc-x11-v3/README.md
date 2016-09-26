Dockerfile to create a Docker image based on Debian 8 64-bits, with X11, to be used for GNU ARM Eclipse QEMU & openOCD builds.

Prerequisites:

	eval "$(boot2docker shellinit)"

To create the Docker image, use:

	docker build --tag "ilegeul/debian:8-gnuarm-gcc-x11-v3" \
	https://github.com/ilg-ul/docker/raw/master/debian/8-gnuarm-gcc-x11-v3/Dockerfile

To create the Docker image locally, use:

	cd ...
	docker build --tag "ilegeul/debian:8-gnuarm-gcc-x11-v3" .

To push the Docker image to the server, use:

	docker push "ilegeul/debian:8-gnuarm-gcc-x11-v3"
