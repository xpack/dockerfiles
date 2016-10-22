FROM ilegeul/debian32:8-gnuarm-gcc-x11-v3
MAINTAINER Liviu Ionescu <ilg@livius.net>
ENTRYPOINT ["linux32"]
WORKDIR /root

RUN \
apt-get -y update && \
apt-get -y install apt-utils && \
apt-get -y dist-upgrade --fix-broken

CMD ["/bin/bash"]
