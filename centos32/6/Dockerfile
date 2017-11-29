FROM scratch
MAINTAINER Liviu Ionescu <ilg@livius.net>
ENTRYPOINT ["linux32"]
ADD rootfs.tar.xz /

RUN linux32 yum -y update

CMD ["/bin/bash"]
