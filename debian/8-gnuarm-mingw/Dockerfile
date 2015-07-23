FROM ilegeul/debian:8-gnuarm-gcc
MAINTAINER Liviu Ionescu <ilg@livius.net>
WORKDIR /root

RUN \
apt-get -y update && \
apt-get -y upgrade && \
apt-get -y install \
nsis dos2unix \
binutils-mingw-w64-i686 \
binutils-mingw-w64-x86-64 \
g++-mingw-w64 \
g++-mingw-w64-i686 \
g++-mingw-w64-x86-64 \
gcc-mingw-w64 \
gcc-mingw-w64-base \
gcc-mingw-w64-i686 \
gcc-mingw-w64-x86-64 \
gdb-mingw-w64 \
gdb-mingw-w64-target \
mingw-w64 \
mingw-w64-i686-dev \
mingw-w64-tools \
mingw-w64-x86-64-dev

CMD ["/bin/bash"]

