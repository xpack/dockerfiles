FROM ilegeul/centos:5-bootstrap-v2
MAINTAINER Liviu Ionescu <ilg@livius.net>
WORKDIR /root

ADD image /xbb-input
RUN \
time bash -x /xbb-input/build.sh

CMD ["/bin/bash"]

