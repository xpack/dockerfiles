FROM ilegeul/debian:8-gnuarm-mingw
MAINTAINER Liviu Ionescu <ilg@livius.net>
WORKDIR /root

RUN \
apt-get -y update && \
apt-get -y upgrade && \
mkdir -p /root/download && \
cd /root/download && \
curl \
-O http://qemu.weilnetz.de/debian/gtk-mingw-w64-x86-64_3.6.4-20131201-2_all.deb \
-O http://qemu.weilnetz.de/debian/gtk2.0-mingw-w64-i686_2.24.10-20120208-2_all.deb \
-O http://qemu.weilnetz.de/debian/libfdt-mingw-w64-i686_1.4.0-2_all.deb \
-O http://qemu.weilnetz.de/debian/libfdt-mingw-w64-x86-64_1.4.0-2_all.deb && \
dpkg -i *.deb && \
apt-get install -f

CMD ["/bin/bash"]

