Dockerfile to create a Docker image based on Debian 8 32-bits, to be used for GNU ARM Eclipse GCC builds.

Prerequisites:

- none


To create the Docker image, use:

	docker build --tag "ilegeul/debian32:8-gnuarm-gcc" \
	https://github.com/ilg-ul/docker/raw/master/debian32/8-gnuarm-gcc/Dockerfile

To create the Docker image locally, use:

	cd ...
	docker build --tag "ilegeul/debian32:8-gnuarm-gcc"  .
