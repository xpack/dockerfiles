Dockerfile to create a Docker image based on Debian 8 64-bits, to be used for GNU ARM Eclipse GCC builds.

Prerequisites:

- none


To create the Docker image, use:

	docker build --tag "ilegeul/debian:8-gnuarm-gcc" \
	https://github.com/ilg-ul/docker/raw/master/debian/8-gnuarm-gcc/Dockerfile

