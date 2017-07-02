FROM ilegeul/debian32:9
MAINTAINER Liviu Ionescu <ilg@livius.net>
WORKDIR /root

RUN \
apt-get -y update && \
apt-get -y upgrade && \
apt-get -y install \
lsb-release \
gcc g++ git make cmake m4 python sed tar zip unzip bzip2 xz-utils \
curl wget \
libtool pkg-config automake autoconf autotools-dev \
gettext libglib2.0-dev \
libx11-dev libxext-dev \
libudev-dev libconfuse-dev libboost-all-dev \
texinfo texlive bison flex doxygen \
patchelf chrpath libx11-dev libxext-dev \
nsis dos2unix \
mingw-w64


CMD ["/bin/bash"]
