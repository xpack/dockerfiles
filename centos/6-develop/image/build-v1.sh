#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Safety settings (see https://gist.github.com/ilg-ul/383869cbb01f61a51c4d).

if [[ ! -z ${DEBUG} ]]
then
  set ${DEBUG} # Activate the expand mode if DEBUG is -x.
else
  DEBUG=""
fi

set -o errexit # Exit if command failed.
set -o pipefail # Exit if pipe failed.
set -o nounset # Exit if variable not set.

# Remove the initial space and instead use '\n'.
IFS=$'\n\t'

# -----------------------------------------------------------------------------

yum install -y yum-plugin-ovl
yum update -y

yum install -y \
redhat-lsb-core \
gcc-c++ \
make \
automake \
pkgconfig \
curl \
xy \
zip \
unzip \
bzip2 \
libtool \
gettext \
texinfo \
bison \
flex \
dos2unix \
patch \
perl \
which \
zlib-devel \
file \
diffutils \
cmake \
libudev-devel

# -----------------------------------------------------------------------------
