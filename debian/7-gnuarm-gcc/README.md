Dockerfile to create a Docker image based on Debian 7 64-bits, to be used for GNU ARM Eclipse GCC builds.

Prerequisites:

- none


To create the Docker image, use:

	git clone https://github.com/ilg-ul/docker.git docker.git
	cd docker.git/debian/7-gnuarm-gcc
	docker build --tag "ilegeul/debian:7-gnuarm-gcc" .

