Dockerfile to create a Docker image based on Debian 7 32-bits, to be used for GNU ARM Eclipse GCC builds.

Prerequisites:

- none


To create the Docker image, use:

	docker build --tag "ilegeul/debian32:7-gnuarm-gcc" \
	https://github.com/ilg-ul/docker/raw/master/debian32/7-gnuarm-gcc/Dockerfile

