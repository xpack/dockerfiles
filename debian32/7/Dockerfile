FROM scratch
MAINTAINER Liviu Ionescu <ilg@livius.net>
ENTRYPOINT ["linux32"]
ADD rootfs.tar.xz /

RUN \
apt-get -y update && \
apt-get -y upgrade

CMD ["/bin/bash"]
