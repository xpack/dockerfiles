FROM ilegeul/debian:7
MAINTAINER Liviu Ionescu <ilg@livius.net>

RUN \
apt-get -y update && \
apt-get -y upgrade && \
apt-get -y install \
lsb-release \
gcc g++ git make m4 python sed tar unzip curl wget \
tar unzip bzip2 xz-utils \
libtool pkg-config automake autoconf autotools-dev \
gettext libglib2.0-dev \
texinfo texlive bison flex doxygen

CMD ["/bin/bash"]
