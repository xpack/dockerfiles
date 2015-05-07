Dockerfile to create a Docker image to based on Debian 7 64-bit base, to be used for GCC builds.

Prerequisites:

- none


To create the Docker image, use:

	git clone https://github.com/ilg-ul/docker.git docker.git
	cd docker.git/debian/7-gcc
	docker build --tag "ilegeul/debian:7-gcc" .

