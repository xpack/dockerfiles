FROM centos:5
MAINTAINER Liviu Ionescu <ilg@livius.net>
WORKDIR /root

RUN \
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-*; \
mv /etc/yum.repos.d/libselinux.repo /etc/yum.repos.d/libselinux.repo.removed; \
sed -i -e 's/^mirrorlist=/## mirrorlist=/g' -e 's|#baseurl=http://mirror.centos.org/centos/$releasever|baseurl=http://vault.centos.org/5.11|g' /etc/yum.repos.d/CentOS-Base.repo; \
yum clean all; \
yum update -y; \
yum downgrade -y libselinux

CMD ["/bin/bash"]

