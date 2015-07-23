FROM ilegeul/debian32:8
MAINTAINER Liviu Ionescu <ilg@livius.net>
ENTRYPOINT ["linux32"]
WORKDIR /root

RUN \
apt-get -y update && \
apt-get -y upgrade && \
apt-get -y install \
lsb-release \
gcc g++ git make cmake m4 python sed tar unzip bzip2 xz-utils \
curl wget \
libtool pkg-config automake autoconf autotools-dev \
gettext libglib2.0-dev \
libudev-dev libconfuse-dev libboost1.55-dev \
texinfo texlive bison flex doxygen

CMD ["/bin/bash"]
