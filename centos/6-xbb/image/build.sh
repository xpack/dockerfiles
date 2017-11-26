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

# Script to build a Docker image with the xPack Build Box (xbb).
#
# Building the newest tools on CentOS 6 directly is now possible,
# but it is not guaranteed that the old GCC 4.4 will continue
# to build future versions.
# So an intermediate solution is used, which includes the most 
# recent versions that can be build with GCC 4.4.
# This intermediate version is used to build the 
# final tools.

# Header files have been installed in:
#    /opt/xbb/include

# Libraries have been installed in:
#    /opt/xbb/lib

# To activate the new build environment, use:
#
#   $ source /opt/xbb/xbb.sh
#   $ xbb_activate

# If you ever happen to want to link against installed libraries
# in a given directory, LIBDIR, you must either use libtool, and
# specify the full pathname of the library, or use the '-LLIBDIR'
# flag during linking and do at least one of the following:
#    - add LIBDIR to the 'LD_LIBRARY_PATH' environment variable
#      during execution
#    - add LIBDIR to the 'LD_RUN_PATH' environment variable
#      during linking
#    - use the '-Wl,-rpath -Wl,LIBDIR' linker flag
#    - have your system administrator add LIBDIR to '/etc/ld.so.conf'

# Credits: Inspired by Holy Build Box build script.

XBB_INPUT="/xbb-input"
XBB_DOWNLOAD="/tmp/xbb-download"
XBB_TMP="/tmp/xbb"

XBB="/opt/xbb"
XBB_BUILD="${XBB_TMP}/xbb-build"

XBB_BOOTSTRAP="/opt/xbb-bootstrap"

MAKE_CONCURRENCY=2

# -----------------------------------------------------------------------------

mkdir -p "${XBB_TMP}"
mkdir -p "${XBB_DOWNLOAD}"

mkdir -p "${XBB}"
mkdir -p "${XBB_BUILD}"

# -----------------------------------------------------------------------------

# Note: __EOF__ is quoted to prevent substitutions here.
cat <<'__EOF__' >> "${XBB}/xbb.sh"

export XBB_FOLDER="/opt/xbb"

function xbb_activate_param()
{
  PREFIX_=${PREFIX_:-${XBB_FOLDER}}

  # Do not include -I... here, use CPPFLAGS.
  EXTRA_CFLAGS_=${EXTRA_CFLAGS_:-""}
  EXTRA_CXXFLAGS_=${EXTRA_CXXFLAGS_:-${EXTRA_CFLAGS_}}

  EXTRA_LDFLAGS_=${EXTRA_LDFLAGS_:-""}

  # Do not include -I... here, use CPPFLAGS.
  EXTRA_STATICLIB_CFLAGS_=${EXTRA_STATICLIB_CFLAGS_:-""}
  EXTRA_STATICLIB_CXXFLAGS_=${EXTRA_STATICLIB_CXXFLAGS_:-${EXTRA_STATICLIB_CFLAGS_}}

  # Do not include -I... here, use CPPFLAGS.
  EXTRA_SHLIB_CFLAGS_=${EXTRA_SHLIB_CFLAGS_:-""}
  EXTRA_SHLIB_CXXFLAGS_=${EXTRA_SHLIB_CXXFLAGS_:-${EXTRA_SHLIB_CFLAGS_}}
  
  EXTRA_SHLIB_LDFLAGS_=${EXTRA_SHLIB_LDFLAGS_:-""}

  EXTRA_LDPATHFLAGS_=${EXTRA_LDPATHFLAGS_:-""}

  export PATH="${PREFIX_}/bin":${PATH}
  export C_INCLUDE_PATH="${PREFIX_}/include"
  export CPLUS_INCLUDE_PATH="${PREFIX_}/include"
  export LIBRARY_PATH="${PREFIX_}/lib"
  export PKG_CONFIG_PATH="${PREFIX_}/lib/pkgconfig":/usr/lib/pkgconfig
  export LD_LIBRARY_PATH="${PREFIX_}/lib"

  export CPPFLAGS="-I\"${PREFIX_}/include\""
  export LDPATHFLAGS="-L\"${PREFIX_}/lib\" ${EXTRA_LDPATHFLAGS_}"

  # Do not include -I... here, use CPPFLAGS.
  local COMMON_CFLAGS_=${COMMON_CFLAGS_:-"-g -O2"}
  local COMMON_CXXFLAGS_=${COMMON_CXXFLAGS_:-${COMMON_CFLAGS_}}

  export CFLAGS="${COMMON_CFLAGS_} ${EXTRA_CFLAGS_}"
	export CXXFLAGS="${COMMON_CXXFLAGS_} ${EXTRA_CXXFLAGS_}"
  export LDFLAGS="${LDPATHFLAGS} ${EXTRA_LDFLAGS_}"

	export STATICLIB_CFLAGS="${COMMON_CFLAGS_} ${EXTRA_STATICLIB_CFLAGS_}"
	export STATICLIB_CXXFLAGS="${COMMON_CXXFLAGS_} ${EXTRA_STATICLIB_CXXFLAGS_}"

	export SHLIB_CFLAGS="${COMMON_CFLAGS_} ${EXTRA_SHLIB_CFLAGS_}"
	export SHLIB_CXXFLAGS="${COMMON_CXXFLAGS_} ${EXTRA_SHLIB_CXXFLAGS_}"
  export SHLIB_LDFLAGS="${LDPATHFLAGS} ${EXTRA_SHLIB_LDFLAGS_}"

  echo "xPack Build Box activated! $(lsb_release -is) $(lsb_release -rs), $(gcc --version | grep gcc), $(ldd --version | grep ldd)"
  echo
  echo PATH=${PATH}
  echo
  echo CFLAGS=${CFLAGS}
  echo CXXFLAGS=${CXXFLAGS}
  echo LDFLAGS=${LDFLAGS}
  echo
  echo STATICLIB_CFLAGS=${STATICLIB_CFLAGS}
  echo STATICLIB_CXXFLAGS=${STATICLIB_CXXFLAGS}
  echo
  echo SHLIB_CFLAGS=${SHLIB_CFLAGS}
  echo SHLIB_CXXFLAGS=${SHLIB_CXXFLAGS}
  echo SHLIB_LDFLAGS=${SHLIB_LDFLAGS}
  echo
  echo LD_LIBRARY_PATH=${LD_LIBRARY_PATH}
  echo PKG_CONFIG_PATH=${PKG_CONFIG_PATH}
}

xbb_activate()
{
  PREFIX_="${XBB}"
  EXTRA_CFLAGS_="-ffunction-sections -fdata-sections"
  EXTRA_LDFLAGS_="-Wl,--gc-sections"
  EXTRA_STATICLIB_CFLAGS_="-ffunction-sections -fdata-sections"
  EXTRA_SHLIB_CFLAGS_="-fPIC"

  xbb_activate_param 
}

xbb_activate_static()
{
  PREFIX_="${XBB}"
  EXTRA_CFLAGS_="-ffunction-sections -fdata-sections -fvisibility=hidden"
  EXTRA_LDFLAGS_="-static-libstdc++ -Wl,--gc-sections"
  EXTRA_STATICLIB_CFLAGS_="-ffunction-sections -fdata-sections -fvisibility=hidden"
  EXTRA_SHLIB_CFLAGS_="-fvisibility=hidden -fPIC"
  EXTRA_SHLIB_LDFLAGS_="-static-libstdc++"

  xbb_activate_param 
}

xbb_activate_shared()
{
  PREFIX_="${XBB}"
  EXTRA_CFLAGS_="-fvisibility=hidden"
  EXTRA_LDFLAGS_="-static-libstdc++"
  EXTRA_STATICLIB_CFLAGS_="-fvisibility=hidden"
  EXTRA_SHLIB_CFLAGS_="-fvisibility=hidden -fPIC"
  EXTRA_SHLIB_LDFLAGS_="-static-libstdc++"

  xbb_activate_param 
}

__EOF__
# The above marker must start in the first column.

# -----------------------------------------------------------------------------

# Note: __EOF__ is quoted to prevent substitutions here.
mkdir -p "${XBB}/bin"
cat <<'__EOF__' >> "${XBB}/bin/pkg-config-verbose"
#! /bin/sh
# pkg-config wrapper for debug

pkg-config $@
RET=$?
OUT=$(pkg-config $@)
echo "($PKG_CONFIG_PATH) | pkg-config $@ -> $RET [$OUT]" >&2
exit ${RET}

__EOF__
# The above marker must start in the first column.

chmod +x "${XBB}/bin/pkg-config-verbose"

# -----------------------------------------------------------------------------

# Use the bootstrap tools.
source "${XBB_BOOTSTRAP}/xbb.sh"

xbb_activate_bootstrap()
{
  PREFIX_="${XBB_BOOTSTRAP}"
  # Use `-fgnu89-inline` to avoid the 'old glibc with new gcc' bug
  # https://github.com/jedisct1/libsodium/issues/202
  EXTRA_CFLAGS_="-ffunction-sections -fdata-sections"
  EXTRA_CXXFLAGS_="-ffunction-sections -fdata-sections "
  EXTRA_LDFLAGS_="-static-libstdc++ -Wl,--gc-sections -Wl,-rpath -Wl,\"${XBB}/lib\""
  EXTRA_STATICLIB_CFLAGS_="-ffunction-sections -fdata-sections"
  EXTRA_STATICLIB_CXXFLAGS_="-ffunction-sections -fdata-sections"
  EXTRA_SHLIB_LDFLAGS_="-static-libstdc++"

  xbb_activate_param
}

xbb_activate_bootstrap

# -----------------------------------------------------------------------------

# SKIP_ALL=true

# SKIP_ZLIB=true
# SKIP_OPENSSL=true
# SKIP_CURL=true

# SKIP_XZ=true
# SKIP_TAR=true

# SKIP_GMP=true
# SKIP_MPFR=true
# SKIP_MPC=true
# SKIP_ISL=true
# SKIP_NETTLE=true
# SKIP_TASN1=true
# SKIP_GNUTLS=true

# SKIP_M4=true
# SKIP_GAWK=true
# SKIP_AUTOCONF=true
# SKIP_AUTOMAKE=true
# SKIP_LIBTOOL=true
# SKIP_GETTEXT=true
# SKIP_PATCH=true
# SKIP_DIFUTILS=true
# SKIP_BISON=true
# SKIP_MAKE=true
# SKIP_WGET=true

# SKIP_PKG_CONFIG=true
# SKIP_FLEX=true
# SKIP_PERL=true
# SKIP_CMAKE=true
# SKIP_PYTHON=true
# SKIP_SCONS=true
# SKIP_NSIS=true
# SKIP_GIT=true

# SKIP_BINUTILS=true
# SKIP_GCC=true

# SKIP_MINGW=true

 SKIP_TEXLIVE=true

# -----------------------------------------------------------------------------

# Defaults

SKIP_ALL=${SKIP_ALL:-false}

SKIP_ZLIB=${SKIP_ZLIBL:-$SKIP_ALL}
SKIP_OPENSSL=${SKIP_OPENSSL:-$SKIP_ALL}
SKIP_CURL=${SKIP_CURL:-$SKIP_ALL}

SKIP_XZ=${SKIP_XZ:-$SKIP_ALL}
SKIP_TAR=${SKIP_TAR:-$SKIP_ALL}

SKIP_GMP=${SKIP_GMP:-$SKIP_ALL}
SKIP_MPFR=${SKIP_MPFR:-$SKIP_ALL}
SKIP_MPC=${SKIP_MPC:-$SKIP_ALL}
SKIP_ISL=${SKIP_ISL:-$SKIP_ALL}
SKIP_NETTLE=${SKIP_NETTLE:-$SKIP_ALL}
SKIP_TASN1=${SKIP_TASN1:-$SKIP_ALL}
SKIP_GNUTLS=${SKIP_GNUTLS:-$SKIP_ALL}

SKIP_M4=${SKIP_M4:-$SKIP_ALL}
SKIP_GAWK=${SKIP_GAWK:-$SKIP_ALL}
SKIP_AUTOCONF=${SKIP_AUTOCONF:-$SKIP_ALL}
SKIP_AUTOMAKE=${SKIP_AUTOMAKE:-$SKIP_ALL}
SKIP_LIBTOOL=${SKIP_LIBTOOL:-$SKIP_ALL}
SKIP_GETTEXT=${SKIP_GETTEXT:-$SKIP_ALL}
SKIP_PATCH=${SKIP_PATCH:-$SKIP_ALL}
SKIP_DIFFUTILS=${SKIP_DIFFUTILS:-$SKIP_ALL}
SKIP_BISON=${SKIP_BISON:-$SKIP_ALL}
SKIP_MAKE=${SKIP_MAKE:-$SKIP_ALL}
SKIP_WGET=${SKIP_WGET:-$SKIP_ALL}

SKIP_PKG_CONFIG=${SKIP_PKG_CONFIG:-$SKIP_ALL}
SKIP_FLEX=${SKIP_FLEX:-$SKIP_ALL}
SKIP_PERL=${SKIP_PERL:-$SKIP_ALL}
SKIP_CMAKE=${SKIP_CMAKE:-$SKIP_ALL}
SKIP_PYTHON=${SKIP_PYTHON:-$SKIP_ALL}
SKIP_SCONS=${SKIP_SCONS:-$SKIP_ALL}
SKIP_NSIS=${SKIP_NSIS:-$SKIP_ALL}
SKIP_GIT=${SKIP_GIT:-$SKIP_ALL}

SKIP_BINUTILS=${SKIP_BINUTILS:-$SKIP_ALL}

SKIP_GCC=${SKIP_GCC:-$SKIP_ALL}

SKIP_MINGW=${SKIP_MINGW:-$SKIP_ALL}

SKIP_TEXLIVE=${SKIP_TEXLIVE:-$SKIP_ALL}

# -----------------------------------------------------------------------------

# SKIP_ZLIB=false
# SKIP_OPENSSL=false
# SKIP_CURL=false

# SKIP_XZ=false
# SKIP_TAR=false

# SKIP_GMP=false
# SKIP_MPFR=false
# SKIP_MPC=false
# SKIP_ISL=false
# SKIP_NETTLE=false
# SKIP_TASN1=false
# SKIP_GNUTLS=false

# SKIP_M4=false
# SKIP_GAWK=false
# SKIP_AUTOCONF=false
# SKIP_AUTOMAKE=false
# SKIP_LIBTOOL=false
# SKIP_GETTEXT=false
# SKIP_PATCH=false
# SKIP_DIFUTILS=false
# SKIP_BISON=false
# SKIP_MAKE=false
# SKIP_WGET=false

# SKIP_PKG_CONFIG=false
# SKIP_FLEX=false
# SKIP_PERL=false
# SKIP_CMAKE=false
# SKIP_PYTHON=false
# SKIP_SCONS=false
# SKIP_NSIS=false
# SKIP_GIT=false

# SKIP_BINUTILS=false
# SKIP_GCC=false

# SKIP_MINGW=false
# SKIP_TEXLIVE=false

# -----------------------------------------------------------------------------
# Build curl with latest openssl.

# http://zlib.net
# http://zlib.net/fossils/
# 2017-01-15
XBB_ZLIB_VERSION="1.2.11"
XBB_ZLIB_FOLDER="zlib-${XBB_ZLIB_VERSION}"
XBB_ZLIB_ARCHIVE="${XBB_ZLIB_FOLDER}.tar.gz"
XBB_ZLIB_URL="http://zlib.net/fossils/${XBB_ZLIB_ARCHIVE}"

# https://www.openssl.org
# https://www.openssl.org/source/
# 2017-Nov-02 
XBB_OPENSSL_VERSION="1.1.0g"
XBB_OPENSSL_FOLDER="openssl-${XBB_OPENSSL_VERSION}"
XBB_OPENSSL_ARCHIVE="${XBB_OPENSSL_FOLDER}.tar.gz"
XBB_OPENSSL_URL="https://www.openssl.org/source/${XBB_OPENSSL_ARCHIVE}"

# https://curl.haxx.se
# https://curl.haxx.se/download/
# 2017-10-23 
XBB_CURL_VERSION="7.56.1"
XBB_CURL_FOLDER="curl-${XBB_CURL_VERSION}"
XBB_CURL_ARCHIVE="${XBB_CURL_FOLDER}.tar.xz"
XBB_CURL_URL="https://curl.haxx.se/download/${XBB_CURL_ARCHIVE}"

# -----------------------------------------------------------------------------
# Build tar with xz support.

# https://tukaani.org/xz/
# https://sourceforge.net/projects/lzmautils/files/
# 2016-12-30
XBB_XZ_VERSION="5.2.3"
XBB_XZ_FOLDER="xz-${XBB_XZ_VERSION}"
XBB_XZ_ARCHIVE="${XBB_XZ_FOLDER}.tar.xz"
XBB_XZ_URL="https://sourceforge.net/projects/lzmautils/files/${XBB_XZ_ARCHIVE}"

# https://www.gnu.org/software/tar/
# https://ftp.gnu.org/gnu/tar/
# 2016-05-16
XBB_TAR_VERSION="1.29"
XBB_TAR_FOLDER="tar-${XBB_TAR_VERSION}"
XBB_TAR_ARCHIVE="${XBB_TAR_FOLDER}.tar.xz"
XBB_TAR_URL="https://ftp.gnu.org/gnu/tar/${XBB_TAR_ARCHIVE}"

# -----------------------------------------------------------------------------

# https://gmplib.org
# https://gmplib.org/download/gmp/
# 16-Dec-2016
XBB_GMP_VERSION="6.1.2"
XBB_GMP_FOLDER="gmp-${XBB_GMP_VERSION}"
XBB_GMP_ARCHIVE="${XBB_GMP_FOLDER}.tar.xz"
XBB_GMP_URL="https://gmplib.org/download/gmp/${XBB_GMP_ARCHIVE}"

# http://www.mpfr.org
# http://www.mpfr.org/mpfr-3.1.6
# http://www.mpfr.org/mpfr-3.1.6/mpfr-3.1.6.tar.bz2
# 7 September 2017
XBB_MPFR_VERSION="3.1.6"
XBB_MPFR_FOLDER="mpfr-${XBB_MPFR_VERSION}"
XBB_MPFR_ARCHIVE="${XBB_MPFR_FOLDER}.tar.xz"
XBB_MPFR_URL="http://www.mpfr.org/${XBB_MPFR_FOLDER}/${XBB_MPFR_ARCHIVE}"

# http://www.multiprecision.org/
# ftp://ftp.gnu.org/gnu/mpc
# ftp://ftp.gnu.org/gnu/mpc/mpc-1.0.3.tar.gz
# February 2015
XBB_MPC_VERSION="1.0.3"
XBB_MPC_FOLDER="mpc-${XBB_MPC_VERSION}"
XBB_MPC_ARCHIVE="${XBB_MPC_FOLDER}.tar.gz"
XBB_MPC_URL="ftp://ftp.gnu.org/gnu/mpc/${XBB_MPC_ARCHIVE}"

# http://isl.gforge.inria.fr
# http://isl.gforge.inria.fr/isl-0.16.1.tar.bz2
# 2016-12-20
XBB_ISL_VERSION="0.18"
XBB_ISL_FOLDER="isl-${XBB_ISL_VERSION}"
XBB_ISL_ARCHIVE="${XBB_ISL_FOLDER}.tar.xz"
XBB_ISL_URL="http://isl.gforge.inria.fr/${XBB_ISL_ARCHIVE}"

# https://www.lysator.liu.se/~nisse/nettle/
# https://ftp.gnu.org/gnu/nettle/
# 2017-11-19
XBB_NETTLE_VERSION="3.4"
XBB_NETTLE_FOLDER="nettle-${XBB_NETTLE_VERSION}"
XBB_NETTLE_ARCHIVE="${XBB_NETTLE_FOLDER}.tar.gz"
XBB_NETTLE_URL="https://ftp.gnu.org/gnu/nettle/${XBB_NETTLE_ARCHIVE}"

# https://www.gnu.org/software/libtasn1/
# http://ftp.gnu.org/gnu/libtasn1/
# 2017-11-19
XBB_TASN1_VERSION="4.12"
XBB_TASN1_FOLDER="libtasn1-${XBB_TASN1_VERSION}"
# .gz only.
XBB_TASN1_ARCHIVE="${XBB_TASN1_FOLDER}.tar.gz"
XBB_TASN1_URL="https://ftp.gnu.org/gnu/libtasn1/${XBB_TASN1_ARCHIVE}"

# http://www.gnutls.org/
# https://www.gnupg.org/ftp/gcrypt/gnutls/v3.5/
# 2017-10-21
XBB_GNUTLS_MAJOR_VERSION="3.5"
XBB_GNUTLS_VERSION="${XBB_GNUTLS_MAJOR_VERSION}.16"
XBB_GNUTLS_FOLDER="gnutls-${XBB_GNUTLS_VERSION}"
XBB_GNUTLS_ARCHIVE="${XBB_GNUTLS_FOLDER}.tar.xz"
XBB_GNUTLS_URL="https://www.gnupg.org/ftp/gcrypt/gnutls/v${XBB_GNUTLS_MAJOR_VERSION}/${XBB_GNUTLS_ARCHIVE}"

# -----------------------------------------------------------------------------
# Build GNU tools.

# https://www.gnu.org/software/m4/
# https://ftp.gnu.org/gnu/m4/
# XBB_M4_VERSION=1.4.17
# 2016-12-31
XBB_M4_VERSION="1.4.18"
XBB_M4_FOLDER="m4-${XBB_M4_VERSION}"
XBB_M4_ARCHIVE="${XBB_M4_FOLDER}.tar.xz"
XBB_M4_URL="https://ftp.gnu.org/gnu/m4/${XBB_M4_ARCHIVE}"

# https://www.gnu.org/software/gawk/
# https://ftp.gnu.org/gnu/gawk/
# 2017-10-19
XBB_GAWK_VERSION="4.2.0"
XBB_GAWK_FOLDER="gawk-${XBB_GAWK_VERSION}"
XBB_GAWK_ARCHIVE="${XBB_GAWK_FOLDER}.tar.xz"
XBB_GAWK_URL="https://ftp.gnu.org/gnu/gawk/${XBB_GAWK_ARCHIVE}"

# https://www.gnu.org/software/autoconf/
# https://ftp.gnu.org/gnu/autoconf/
# 2012-04-24
XBB_AUTOCONF_VERSION="2.69"
XBB_AUTOCONF_FOLDER="autoconf-${XBB_AUTOCONF_VERSION}"
XBB_AUTOCONF_ARCHIVE="${XBB_AUTOCONF_FOLDER}.tar.xz"
XBB_AUTOCONF_URL="https://ftp.gnu.org/gnu/autoconf/${XBB_AUTOCONF_ARCHIVE}"

# https://www.gnu.org/software/automake/
# https://ftp.gnu.org/gnu/automake/
# 2015-01-05
XBB_AUTOMAKE_VERSION="1.15"
XBB_AUTOMAKE_FOLDER="automake-${XBB_AUTOMAKE_VERSION}"
XBB_AUTOMAKE_ARCHIVE="${XBB_AUTOMAKE_FOLDER}.tar.xz"
XBB_AUTOMAKE_URL="https://ftp.gnu.org/gnu/automake/${XBB_AUTOMAKE_ARCHIVE}"

# https://www.gnu.org/software/libtool/
# http://gnu.mirrors.linux.ro/libtool/
# 15-Feb-2015
XBB_LIBTOOL_VERSION="2.4.6"
XBB_LIBTOOL_FOLDER="libtool-${XBB_LIBTOOL_VERSION}"
XBB_LIBTOOL_ARCHIVE="${XBB_LIBTOOL_FOLDER}.tar.xz"
XBB_LIBTOOL_URL="http://ftpmirror.gnu.org/libtool/${XBB_LIBTOOL_ARCHIVE}"

# https://www.gnu.org/software/gettext/
# https://ftp.gnu.org/gnu/gettext/
# 2016-06-09
XBB_GETTEXT_VERSION="0.19.8"
XBB_GETTEXT_FOLDER="gettext-${XBB_GETTEXT_VERSION}"
XBB_GETTEXT_ARCHIVE="${XBB_GETTEXT_FOLDER}.tar.xz"
XBB_GETTEXT_URL="https://ftp.gnu.org/gnu/gettext/${XBB_GETTEXT_ARCHIVE}"

# https://www.gnu.org/software/patch/
# https://ftp.gnu.org/gnu/patch/
# 2015-03-06
XBB_PATCH_VERSION="2.7.5"
XBB_PATCH_FOLDER="patch-${XBB_PATCH_VERSION}"
XBB_PATCH_ARCHIVE="${XBB_PATCH_FOLDER}.tar.xz"
XBB_PATCH_URL="https://ftp.gnu.org/gnu/patch/${XBB_PATCH_ARCHIVE}"

# https://www.gnu.org/software/diffutils/
# https://ftp.gnu.org/gnu/diffutils/
# 2017-05-21
XBB_DIFFUTILS_VERSION="3.6"
XBB_DIFFUTILS_FOLDER="diffutils-${XBB_DIFFUTILS_VERSION}"
XBB_DIFFUTILS_ARCHIVE="${XBB_DIFFUTILS_FOLDER}.tar.xz"
XBB_DIFFUTILS_URL="https://ftp.gnu.org/gnu/diffutils/${XBB_DIFFUTILS_ARCHIVE}"

# https://www.gnu.org/software/bison/
# https://ftp.gnu.org/gnu/bison/
# 2015-01-23
XBB_BISON_VERSION="3.0.4"
XBB_BISON_FOLDER="bison-${XBB_BISON_VERSION}"
XBB_BISON_ARCHIVE="${XBB_BISON_FOLDER}.tar.xz"
XBB_BISON_URL="https://ftp.gnu.org/gnu/bison/${XBB_BISON_ARCHIVE}"

# https://www.gnu.org/software/make/
# https://ftp.gnu.org/gnu/make/
# 2016-06-10
XBB_MAKE_VERSION="4.2.1"
XBB_MAKE_FOLDER="make-${XBB_MAKE_VERSION}"
# Only .bz2 available.
XBB_MAKE_ARCHIVE="${XBB_MAKE_FOLDER}.tar.bz2"
XBB_MAKE_URL="https://ftp.gnu.org/gnu/make/${XBB_MAKE_ARCHIVE}"

# https://www.gnu.org/software/wget/
# https://ftp.gnu.org/gnu/wget/
# 2016-06-10
XBB_WGET_VERSION="1.19"
XBB_WGET_FOLDER="wget-${XBB_WGET_VERSION}"
XBB_WGET_ARCHIVE="${XBB_WGET_FOLDER}.tar.xz"
XBB_WGET_URL="https://ftp.gnu.org/gnu/wget/${XBB_WGET_ARCHIVE}"

# -----------------------------------------------------------------------------
# Build third party tools.

# https://www.freedesktop.org/wiki/Software/pkg-config/
# https://pkgconfig.freedesktop.org/releases/
# 2017-03-20
XBB_PKG_CONFIG_VERSION="0.29.2"
XBB_PKG_CONFIG_FOLDER="pkg-config-${XBB_PKG_CONFIG_VERSION}"
XBB_PKG_CONFIG_ARCHIVE="${XBB_PKG_CONFIG_FOLDER}.tar.gz"
XBB_PKG_CONFIG_URL="https://pkgconfig.freedesktop.org/releases/${XBB_PKG_CONFIG_ARCHIVE}"

# https://github.com/westes/flex
# https://github.com/westes/flex/releases
# May 6, 2017
XBB_FLEX_VERSION="2.6.4"
XBB_FLEX_FOLDER="flex-${XBB_FLEX_VERSION}"
XBB_FLEX_ARCHIVE="${XBB_FLEX_FOLDER}.tar.gz"
XBB_FLEX_URL="https://github.com/westes/flex/releases/download/v${XBB_FLEX_VERSION}/${XBB_FLEX_ARCHIVE}"

# https://www.cpan.org
# http://www.cpan.org/src/
# 2017-09-22
XBB_PERL_MAJOR_VERSION="5.0"
XBB_PERL_VERSION="5.26.1"
XBB_PERL_FOLDER="perl-${XBB_PERL_VERSION}"
XBB_PERL_ARCHIVE="${XBB_PERL_FOLDER}.tar.gz"
XBB_PERL_URL="http://www.cpan.org/src/${XBB_PERL_MAJOR_VERSION}/${XBB_PERL_ARCHIVE}"

# https://cmake.org
# https://cmake.org/download/
# November 10, 2017
XBB_CMAKE_MAJOR_VERSION="3.9"
XBB_CMAKE_VERSION="${XBB_CMAKE_MAJOR_VERSION}.6"
XBB_CMAKE_FOLDER="cmake-${XBB_CMAKE_VERSION}"
XBB_CMAKE_ARCHIVE="${XBB_CMAKE_FOLDER}.tar.gz"
XBB_CMAKE_URL="https://cmake.org/files/v${XBB_CMAKE_MAJOR_VERSION}/${XBB_CMAKE_ARCHIVE}"

# https://www.python.org
# https://www.python.org/downloads/source/
# 2017-09-16
XBB_PYTHON_VERSION="2.7.14"
XBB_PYTHON_FOLDER="Python-${XBB_PYTHON_VERSION}"
XBB_PYTHON_ARCHIVE="${XBB_PYTHON_FOLDER}.tar.xz"
XBB_PYTHON_URL="https://www.python.org/ftp/python/${XBB_PYTHON_VERSION}/${XBB_PYTHON_ARCHIVE}"

# http://scons.org
# https://sourceforge.net/projects/scons/files/scons/3.0.1/
# 2017-09-16
XBB_SCONS_VERSION="3.0.1"
XBB_SCONS_FOLDER="scons-${XBB_SCONS_VERSION}"
XBB_SCONS_ARCHIVE="${XBB_SCONS_FOLDER}.tar.gz"
XBB_SCONS_URL="https://sourceforge.net/projects/scons/files/scons/${XBB_SCONS_VERSION}/${XBB_SCONS_ARCHIVE}"

# https://git-scm.com/
# https://www.kernel.org/pub/software/scm/git/
# 30-Oct-2017
XBB_GIT_VERSION="2.15.0"
XBB_GIT_FOLDER="git-${XBB_GIT_VERSION}"
XBB_GIT_ARCHIVE="${XBB_GIT_FOLDER}.tar.xz"
XBB_GIT_URL="https://www.kernel.org/pub/software/scm/git//${XBB_GIT_ARCHIVE}"


# -----------------------------------------------------------------------------
# Other GCC dependencies (from https://gcc.gnu.org/install/prerequisites.html):

# gperf version 2.7.2 (or later)
#   Necessary when modifying gperf input files, e.g. gcc/cp/cfns.gperf to regenerate its associated header file, e.g. gcc/cp/cfns.h.
#
# DejaGnu 1.4.4
# Expect
# Tcl
#   Necessary to run the GCC testsuite
#
# autogen version 5.5.4 (or later) and
# guile version 1.4.1 (or later)
#   Necessary to regenerate fixinc/fixincl.x from fixinc/inclhack.def and fixinc/*.tpl.
#
# Texinfo version 4.8 or later is required for make pdf.
# TeX (any working version)

# XBB_ZLIB_VERSION=1.2.11

# -----------------------------------------------------------------------------
# And finally build the binutils and gcc.

# https://ftp.gnu.org/gnu/binutils/
# 2017-07-24
XBB_BINUTILS_VERSION="2.29"
XBB_BINUTILS_FOLDER="binutils-${XBB_BINUTILS_VERSION}"
XBB_BINUTILS_ARCHIVE="${XBB_BINUTILS_FOLDER}.tar.xz"
XBB_BINUTILS_URL="https://ftp.gnu.org/gnu/binutils/${XBB_BINUTILS_ARCHIVE}"

# https://gcc.gnu.org
# https://gcc.gnu.org/wiki/InstallingGCC
# https://ftp.gnu.org/gnu/gcc/
# 2017-08-14
XBB_GCC_VERSION="7.2.0"
XBB_GCC_FOLDER="gcc-${XBB_GCC_VERSION}"
XBB_GCC_ARCHIVE="${XBB_GCC_FOLDER}.tar.xz"
XBB_GCC_URL="https://ftp.gnu.org/gnu/gcc/gcc-${XBB_GCC_VERSION}/${XBB_GCC_ARCHIVE}"

# -----------------------------------------------------------------------------

# http://mingw-w64.org/doku.php/start
# https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/
# 2017-11-04
XBB_MINGW_VERSION="5.0.3"
XBB_MINGW_FOLDER="mingw-w64-v${XBB_MINGW_VERSION}"
XBB_MINGW_ARCHIVE="${XBB_MINGW_FOLDER}.tar.bz2"
XBB_MINGW_URL="https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/${XBB_MINGW_ARCHIVE}"

# -----------------------------------------------------------------------------

function extract()
{
  local ARCHIVE_NAME="$1"

  tar xf "${ARCHIVE_NAME}"
}

function download()
{
  local ARCHIVE_NAME="$1"
  local URL="$2"

  if [ ! -f "${XBB_DOWNLOAD}/${ARCHIVE_NAME}" ]
  then
    rm -f "${XBB_DOWNLOAD}/${ARCHIVE_NAME}.download"
    curl --fail -L -o "${XBB_DOWNLOAD}/${ARCHIVE_NAME}.download" "${URL}"
    mv "${XBB_DOWNLOAD}/${ARCHIVE_NAME}.download" "${XBB_DOWNLOAD}/${ARCHIVE_NAME}"
  fi
}

function download_and_extract()
{
  local ARCHIVE_NAME="$1"
  local URL="$2"

  download "${ARCHIVE_NAME}" "${URL}"
  extract "${XBB_DOWNLOAD}/${ARCHIVE_NAME}"
}

function eval_bool()
{
  local VAL="$1"
  [[ "${VAL}" = 1 || "${VAL}" = true || "${VAL}" = yes || "${VAL}" = y ]]
}

# -----------------------------------------------------------------------------
# WARNING: the order is important, since some of the builds depend
# on previous ones.
# For extra safety, the ${XBB} is not permanently in PATH,
# it is added explicitly with xbb_activate in sub-shells.
# Generally only the static versions of the libraries are build.
# (the exceptions are libcrypto.so libcurl.so libssl.so)

if ! eval_bool "${SKIP_ZLIB}"
then
  echo
  echo "Building zlib ${XBB_ZLIB_VERSION}..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_ZLIB_ARCHIVE}" "${XBB_ZLIB_URL}"

  pushd "$XBB_ZLIB_FOLDER"
  (
    # Better leave both static and dynamic, some apps fail without the expected one.
    ./configure --prefix="${XBB}"
    make -j${MAKE_CONCURRENCY}
    make install

    strip --strip-debug "${XBB}/lib/libz.a" 
    strip --strip-debug "${XBB}/lib/libz.so."*
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd
fi

if ! eval_bool "${SKIP_OPENSSL}"
then
  echo
  echo "Building openssl ${XBB_OPENSSL_VERSION}..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_OPENSSL_ARCHIVE}" "${XBB_OPENSSL_URL}"

  pushd "${XBB_OPENSSL_FOLDER}"
  (
    # OpenSSL already passes optimization flags regardless of CFLAGS.
		export CFLAGS=`echo "${STATICLIB_CFLAGS}" | sed 's/-O2//'`

    # Without the 'shared' option some further builds fail.
    ./config --prefix="${XBB}" \
      --openssldir="${XBB}/openssl" \
      threads zlib no-shared no-sse2
    make
    make install_sw

    strip --strip-all "${XBB}/bin/openssl"

    strip --strip-debug "${XBB}/lib/libcrypto.a" 
    strip --strip-debug "${XBB}/lib/libssl.a" 

    # no-shared
    # strip --strip-debug "${XBB}/lib/libcrypto.so."*
    # strip --strip-debug "${XBB}/lib/libssl.so."*

    # Patch the .pc files to add refs to libs.
    cat "${XBB}/lib/pkgconfig/openssl.pc"
    sed -i 's/^Libs:.*/Libs: -L${libdir} -lssl -lcrypto -ldl/' "${XBB}/lib/pkgconfig/openssl.pc"
		sed -i 's/^Libs.private:.*/Libs.private: -L${libdir} -lssl -lcrypto -ldl -lz/' "${XBB}/lib/pkgconfig/openssl.pc"
		cat "${XBB}/lib/pkgconfig/openssl.pc"

    cat "${XBB}/lib/pkgconfig/libssl.pc"
    sed -i 's/^Libs:.*/Libs: -L${libdir} -lssl -lcrypto -ldl/' "${XBB}/lib/pkgconfig/libssl.pc"
		sed -i 's/^Libs.private:.*/Libs.private: -L${libdir} -lssl -lcrypto -ldl -lz/' "${XBB}/lib/pkgconfig/libssl.pc"
    cat "${XBB}/lib/pkgconfig/libssl.pc"
    
    if [ ! -f "${XBB}/openssl/cert.pem" ]
    then
      mkdir -p "${XBB}/openssl"
      ln -s /etc/pki/tls/certs/ca-bundle.crt "${XBB}/openssl/cert.pem"
    fi
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd
fi

if ! eval_bool "${SKIP_CURL}"
then
  echo
  echo "Building curl ${XBB_CURL_VERSION}..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_CURL_ARCHIVE}" "${XBB_CURL_URL}"

  pushd "${XBB_CURL_FOLDER}"
  (
    export CFLAGS="${STATICLIB_CFLAGS}"

    # --disable-ftp --disable-ftps 
    # ./buildconf
    ./configure --prefix="${XBB}" --disable-shared --disable-debug --enable-optimize --disable-werror \
			--disable-curldebug --enable-symbol-hiding --disable-ares --disable-manual --disable-ldap --disable-ldaps \
			--disable-rtsp --disable-dict --disable-gopher --disable-imap \
			--disable-imaps --disable-pop3 --disable-pop3s --without-librtmp --disable-smtp --disable-smtps \
			--disable-telnet --disable-tftp --disable-smb --disable-versioned-symbols \
			--without-libmetalink --without-libidn --without-libssh2 --without-libmetalink --without-nghttp2 \
			--with-ssl
    make -j${MAKE_CONCURRENCY}
    make install

    strip --strip-all "${XBB}/bin/curl"
    strip --strip-debug "${XBB}/lib/libcurl.a"

    # --disable-shared
    # strip --strip-debug "${XBB}/lib/libcurl.so"
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

# -----------------------------------------------------------------------------

if ! eval_bool "${SKIP_XZ}"
then
  echo
  echo "Building xz ${XBB_XZ_VERSION}..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_XZ_ARCHIVE}" "${XBB_XZ_URL}"

  pushd "${XBB_XZ_FOLDER}"
  (
    export CFLAGS="${STATICLIB_CFLAGS} -Wno-implicit-fallthrough"

    ./configure --prefix="${XBB}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

# Requires xz
if ! eval_bool "${SKIP_TAR}"
then
  echo
  echo "Building tar ${XBB_TAR_VERSION}..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_TAR_ARCHIVE}" "${XBB_TAR_URL}"

  pushd "${XBB_TAR_FOLDER}"
  (
    # Avoid 'configure: error: you should not run configure as root'.
    export FORCE_UNSAFE_CONFIGURE=1

    ./configure --prefix="${XBB}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

# -----------------------------------------------------------------------------
# Libraries.

if ! eval_bool "${SKIP_GMP}"
then
  echo
  echo "Building gmp ${XBB_GMP_VERSION}..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_GMP_ARCHIVE}" "${XBB_GMP_URL}"

  pushd "${XBB_GMP_FOLDER}"
  (
    export CFLAGS="${STATICLIB_CFLAGS}"

    ./configure --prefix="${XBB}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd
fi

if ! eval_bool "${SKIP_MPFR}"
then
  echo
  echo "Building mpfr ${XBB_MPFR_VERSION}..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_MPFR_ARCHIVE}" "${XBB_MPFR_URL}"

  pushd "${XBB_MPFR_FOLDER}"
  (
    export CFLAGS="${STATICLIB_CFLAGS}"

    ./configure --prefix="${XBB}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd
fi

if ! eval_bool "${SKIP_MPC}"
then
  echo
  echo "Building mpc ${XBB_MPC_VERSION}..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_MPC_ARCHIVE}" "${XBB_MPC_URL}"

  pushd "${XBB_MPC_FOLDER}"
  (
    export CFLAGS="${STATICLIB_CFLAGS}"

    ./configure --prefix="${XBB}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd
fi

if ! eval_bool "${SKIP_ISL}"
then
  echo
  echo "Building isl ${XBB_ISL_VERSION}..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_ISL_ARCHIVE}" "${XBB_ISL_URL}"

  pushd "$XBB_ISL_FOLDER"
  (
    export CFLAGS="${STATICLIB_CFLAGS}"

    ./configure --prefix="${XBB}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd
fi

if ! eval_bool "${SKIP_NETTLE}"
then
  echo
  echo "Building nettle ${XBB_NETTLE_VERSION}..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_NETTLE_ARCHIVE}" "${XBB_NETTLE_URL}"

  pushd "$XBB_NETTLE_FOLDER"
  (
    export CFLAGS="${STATICLIB_CFLAGS}"
    # export CFLAGS="${SHLIB_CFLAGS}"
    # export LDFLAGS="${SHLIB_LDFLAGS}"

    ./configure --prefix="${XBB}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install

    echo
    echo "${XBB}/lib64/pkgconfig/nettle.pc"
    cat "${XBB}/lib64/pkgconfig/nettle.pc"

    echo
    echo "${XBB}/lib64/pkgconfig/hogweed.pc"
    cat "${XBB}/lib64/pkgconfig/hogweed.pc"

  )
  if [[ "$?" != 0 ]]; then false; fi
  popd
fi

if ! eval_bool "${SKIP_TASN1}"
then
  echo
  echo "Building tasn1 ${XBB_TASN1_VERSION}..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_TASN1_ARCHIVE}" "${XBB_TASN1_URL}"

  pushd "$XBB_TASN1_FOLDER"
  (
    export CFLAGS="${STATICLIB_CFLAGS} -Wno-logical-op -Wno-missing-prototypes"
    # export CFLAGS="${SHLIB_CFLAGS}"
    # export LDFLAGS="${SHLIB_LDFLAGS}"

    ./configure --prefix="${XBB}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install

    echo
    echo "${XBB}/lib/pkgconfig/libtasn1.pc"
    cat "${XBB}/lib/pkgconfig/libtasn1.pc"
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd
fi

# Requires libtasn1 & nettle.
if ! eval_bool "${SKIP_GNUTLS}"
then
  echo
  echo "Building gnutls ${XBB_GNUTLS_VERSION}..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_GNUTLS_ARCHIVE}" "${XBB_GNUTLS_URL}"

  pushd "$XBB_GNUTLS_FOLDER"
  (
    export PATH="${XBB}/bin":${PATH}
    export CFLAGS="${STATICLIB_CFLAGS} -Wno-parentheses -Wno-bad-function-cast -Wno-unused-macros -Wno-bad-function-cast -Wno-unused-variable -Wno-pointer-sign -Wno-implicit-fallthrough -Wno-format-truncation -Wno-missing-prototypes -Wno-missing-declarations"
    export CXXFLAGS="${STATICLIB_CXXFLAGS}"
    # Without it 'error: libtasn1.h: No such file or directory'
    export CPPFLAGS="-I${XBB}/include ${CPPFLAGS}"
    export LDFLAGS="-L\"${XBB}/lib\" -L\"${XBB}/lib64\" ${LDFLAGS}"
    export PKG_CONFIG_PATH="${XBB}/lib/pkgconfig:${XBB}/lib64/pkgconfig:${PKG_CONFIG_PATH}"
    export PKG_CONFIG="${XBB}/bin/pkg-config-verbose"

    ./configure --prefix="${XBB}" \
      --disable-shared \
      --enable-static \
      --with-included-unistring \
      --without-p11-kit

    make -j${MAKE_CONCURRENCY}
    make install-strip

    echo
    echo "${XBB}/lib/pkgconfig/gnutls.pc"
    cat "${XBB}/lib/pkgconfig/gnutls.pc"

    # Patch the gnutls.pc to add dependednt libs, to make wget build.
    sed -i 's/^Libs:.*/Libs: -L${libdir} -L${exec_prefix}\/lib64 -lgnutls -ltasn1 -lnettle -lhogweed -lgmp/' "${XBB}/lib/pkgconfig/gnutls.pc"
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd
fi

# -----------------------------------------------------------------------------

if ! eval_bool "${SKIP_M4}"
then
  echo
  echo "Building m4 ${XBB_M4_VERSION}..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_M4_ARCHIVE}" "${XBB_M4_URL}"

  pushd "${XBB_M4_FOLDER}"
  (
    ./configure --prefix="${XBB}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

if ! eval_bool "${SKIP_GAWK}"
then
  echo
  echo "Building gawk ${XBB_GAWK_VERSION}..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_GAWK_ARCHIVE}" "${XBB_GAWK_URL}"

  pushd "${XBB_GAWK_FOLDER}"
  (
    ./configure --prefix="${XBB}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

if ! eval_bool "${SKIP_AUTOCONF}"
then
  echo
  echo "Building autoconf ${XBB_AUTOCONF_VERSION}..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_AUTOCONF_ARCHIVE}" "${XBB_AUTOCONF_URL}"

  pushd "${XBB_AUTOCONF_FOLDER}"
  (
    ./configure --prefix="${XBB}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

if ! eval_bool "${SKIP_AUTOMAKE}"
then
  echo
  echo "Building automake ${XBB_AUTOMAKE_VERSION}..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_AUTOMAKE_ARCHIVE}" "${XBB_AUTOMAKE_URL}"

  pushd "${XBB_AUTOMAKE_FOLDER}"
  (
    ./configure --prefix="${XBB}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

if ! eval_bool "${SKIP_LIBTOOL}"
then
  echo
  echo "Building libtool ${XBB_LIBTOOL_VERSION}..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_LIBTOOL_ARCHIVE}" "${XBB_LIBTOOL_URL}"

  pushd "${XBB_LIBTOOL_FOLDER}"
  (
    ./configure --prefix="${XBB}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

if ! eval_bool "${SKIP_GETTEXT}"
then
  echo
  echo "Building gettext ${XBB_GETTEXT_VERSION}..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_GETTEXT_ARCHIVE}" "${XBB_GETTEXT_URL}"

  pushd "${XBB_GETTEXT_FOLDER}"
  (
    export CFLAGS="${CFLAGS} -Wno-discarded-qualifiers"

    ./configure --prefix="${XBB}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

if ! eval_bool "${SKIP_PATCH}"
then
  echo
  echo "Building patch ${XBB_PATCH_VERSION}..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_PATCH_ARCHIVE}" "${XBB_PATCH_URL}"

  pushd "${XBB_PATCH_FOLDER}"
  (
    ./configure --prefix="${XBB}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

if ! eval_bool "${SKIP_DIFFUTILS}"
then
  echo
  echo "Building diffutils ${XBB_DIFFUTILS_VERSION}..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_DIFFUTILS_ARCHIVE}" "${XBB_DIFFUTILS_URL}"

  pushd "${XBB_DIFFUTILS_FOLDER}"
  (
    ./configure --prefix="${XBB}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

if ! eval_bool "${SKIP_BISON}"
then
  echo
  echo "Building bison ${XBB_BISON_VERSION}..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_BISON_ARCHIVE}" "${XBB_BISON_URL}"

  pushd "${XBB_BISON_FOLDER}"
  (
    ./configure --prefix="${XBB}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

if ! eval_bool "${SKIP_MAKE}"
then
  echo
  echo "Building make ${XBB_MAKE_VERSION}..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_MAKE_ARCHIVE}" "${XBB_MAKE_URL}"

  pushd "${XBB_MAKE_FOLDER}"
  (
    ./configure --prefix="${XBB}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

# http://git.savannah.gnu.org/cgit/wget.git/tree/configure.ac

# Requires gnutls.
if ! eval_bool "${SKIP_WGET}"
then
  echo
  echo "Building wget ${XBB_WGET_VERSION}..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_WGET_ARCHIVE}" "${XBB_WGET_URL}"

  pushd "${XBB_WGET_FOLDER}"
  (
    export PATH="${XBB}/bin":${PATH}
    export CFLAGS="${STATICLIB_CFLAGS} -Wno-implicit-function-declaration"
    export CXXFLAGS="${STATICLIB_CXXFLAGS}"
    # export CPPFLAGS="-I${XBB}/include ${CPPFLAGS}"
    export LDFLAGS="-v ${LDFLAGS}"
    export PKG_CONFIG_PATH="${XBB}/lib/pkgconfig:${XBB}/lib64/pkgconfig:${PKG_CONFIG_PATH}"
    export PKG_CONFIG="${XBB}/bin/pkg-config-verbose"

    ./configure --prefix="${XBB}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

# -----------------------------------------------------------------------------

if ! eval_bool "${SKIP_PKG_CONFIG}"
then
  echo
  echo "Building pkg-config ${XBB_PKG_CONFIG_VERSION}..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_PKG_CONFIG_ARCHIVE}" "${XBB_PKG_CONFIG_URL}"

  pushd "${XBB_PKG_CONFIG_FOLDER}"
  (
    export CFLAGS="${CFLAGS} -Wno-unused-value"

    ./configure --prefix="${XBB}" --with-internal-glib
    rm -f "${XBB}/bin"/*pkg-config
    make -j${MAKE_CONCURRENCY} install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

# Requires gettext
if ! eval_bool "${SKIP_FLEX}"
then
  echo
  echo "Building flex ${XBB_FLEX_VERSION}..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_FLEX_ARCHIVE}" "${XBB_FLEX_URL}"

  pushd "${XBB_FLEX_FOLDER}"
  (
    ./autogen.sh
    ./configure --prefix="${XBB}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

if ! eval_bool "${SKIP_PERL}"
then
  echo
  echo "Building perl ${XBB_PERL_VERSION}..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_PERL_ARCHIVE}" "${XBB_PERL_URL}"

  pushd "${XBB_PERL_FOLDER}"
  (
    # GCC 7.2.0 does not provide a 'cc'.
    # -Dcc is necessary to avoid picking up the original program.
    export CFLAGS="${CFLAGS} -Wno-implicit-fallthrough -Wno-clobbered -Wno-int-in-bool-context"
    ./Configure -des \
      -Dprefix="${XBB}" \
      -Dcc=gcc \
      -Dccflags="${CFLAGS}"
    make -j${MAKE_CONCURRENCY}
    make install-strip

    curl -L http://cpanmin.us | perl - App::cpanminus
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

# -----------------------------------------------------------------------------

if ! eval_bool "${SKIP_CMAKE}"
then
  echo
  echo "Installing cmake ${XBB_CMAKE_VERSION}..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_CMAKE_ARCHIVE}" "${XBB_CMAKE_URL}"

  pushd "${XBB_CMAKE_FOLDER}"
  (
    ./configure --prefix="${XBB}" \
      --parallel=${MAKE_CONCURRENCY} \
      --no-qt-gui \
      --no-system-libs 
    make -j${MAKE_CONCURRENCY}
    make install

    strip --strip-all ${XBB}/bin/cmake
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

if ! eval_bool "${SKIP_PYTHON}"
then
  echo
  echo "Installing python ${XBB_PYTHON_VERSION}..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_PYTHON_ARCHIVE}" "${XBB_PYTHON_URL}"

  pushd "${XBB_PYTHON_FOLDER}"
  (
    # If you want a release build with all optimizations active (LTO, PGO, etc),
    # please run ./configure --enable-optimizations

    export CFLAGS="${CFLAGS} -Wno-int-in-bool-context -Wno-maybe-uninitialized -Wno-nonnull"

    ./configure --prefix="${XBB}"
    make -j${MAKE_CONCURRENCY} install

    strip --strip-all "${XBB}/bin/python"
    strip --strip-debug "${XBB}"/lib/python*/lib-dynload/*.so
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
 
  (
    # Install setuptools and pip. Be sure the new version is used.
    echo "Installing setuptools and pip..."
    curl -OL --fail https://bootstrap.pypa.io/ez_setup.py
    "${XBB}/bin/python" ez_setup.py
    rm -f ez_setup.py
    "${XBB}/bin/easy_install" pip
    rm -f /setuptools*.zip
  )
fi

if ! eval_bool "${SKIP_SCONS}"
then
  echo
  echo "Installing scons ${XBB_SCONS_VERSION}..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_SCONS_ARCHIVE}" "${XBB_SCONS_URL}"

  pushd "${XBB_SCONS_FOLDER}"
  (
    "${XBB}/bin/python" setup.py install --prefix="${XBB}"
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r

fi

if ! eval_bool "${SKIP_GIT}"
then
  echo
  echo "Installing git ${XBB_GIT_VERSION}..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_GIT_ARCHIVE}" "${XBB_GIT_URL}"

  pushd "${XBB_GIT_FOLDER}"
  (
    make configure 
	  ./configure --prefix="${XBB}"
	  make all -j${MAKE_CONCURRENCY}
    make install

    strip --strip-all "${XBB}/bin"/git "${XBB}/bin"/git-[rsu]*
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

# -----------------------------------------------------------------------------

if ! eval_bool "${SKIP_BINUTILS}"
then
  echo
  echo "Building native binutils ${XBB_BINUTILS_VERSION}..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_BINUTILS_ARCHIVE}" "${XBB_BINUTILS_URL}"

  mkdir -p "${XBB_BINUTILS_FOLDER}-native-build"
  pushd "${XBB_BINUTILS_FOLDER}-native-build"
  (
    export CFLAGS="${CFLAGS} -Wno-sign-compare"

    "${XBB_BUILD}/${XBB_BINUTILS_FOLDER}/configure" --prefix="${XBB}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

# -----------------------------------------------------------------------------
# GCC.

if ! eval_bool "${SKIP_GCC}"
then
  echo
  echo "Building native gcc ${XBB_GCC_VERSION}..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_GCC_ARCHIVE}" "${XBB_GCC_URL}"

  mkdir -p "${XBB_GCC_FOLDER}-build"
  pushd "${XBB_GCC_FOLDER}-build"
  (
    export CFLAGS="${CFLAGS} -Wno-sign-compare"
    export CXXFLAGS="${CXXFLAGS} -Wno-sign-compare"

    # --disable-shared failed with errors in libstdc++-v3
    "${XBB_BUILD}/${XBB_GCC_FOLDER}/configure" --prefix="${XBB}" \
      --enable-languages=c,c++ \
      --disable-multilib
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd
fi

# -----------------------------------------------------------------------------
# mingw-w64

# https://sourceforge.net/p/mingw-w64/wiki2/Cross%20Win32%20and%20Win64%20compiler/
# https://sourceforge.net/p/mingw-w64/mingw-w64/ci/master/tree/configure

mingw_target=x86_64-w64-mingw32
# mingw_target=i686-w64-mingw32

mingw_build=x86_64-linux-gnu

if ! eval_bool "${SKIP_MINGW}"
then

  echo
  echo "Building mingw-w64 binutils ${XBB_BINUTILS_VERSION}..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_BINUTILS_ARCHIVE}" "${XBB_BINUTILS_URL}"

  mkdir -p "${XBB_BINUTILS_FOLDER}-mingw-build"
  pushd "${XBB_BINUTILS_FOLDER}-mingw-build"
  (
    export CFLAGS="${CFLAGS} -Wno-sign-compare"

    "${XBB_BUILD}/${XBB_BINUTILS_FOLDER}/configure" \
      --prefix="${XBB}" \
      --with-sysroot="${XBB}" \
      --disable-shared \
      --enable-static \
      --target=${mingw_target} \
      --disable-multilib

    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r

  echo
  echo "Building mingw-w64 headers ${XBB_MINGW_VERSION}..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_MINGW_ARCHIVE}" "${XBB_MINGW_URL}"

  mkdir -p "${XBB_MINGW_FOLDER}-headers-build"
  pushd "${XBB_MINGW_FOLDER}-headers-build"
  (
    export PATH="${XBB}/bin":${PATH}

    "${XBB_BUILD}/${XBB_MINGW_FOLDER}/mingw-w64-headers/configure" \
      --prefix="${XBB}/${mingw_target}" \
      --build="${mingw_build}" \
      --host="${mingw_target}"

    make -j${MAKE_CONCURRENCY}
    make install-strip

    # GCC requires the `x86_64-w64-mingw32` folder be mirrored as `mingw` 
    # in the same root. 
    (cd "${XBB}"; ln -s "${mingw_target}" "mingw")

    # For non-multilib builds, links to "lib32" and "lib64" are no longer 
    # needed, "lib" is enough.
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r

  echo
  echo "Building mingw-w64 gcc ${XBB_GCC_VERSION}, step 1..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_GCC_ARCHIVE}" "${XBB_GCC_URL}"

  mkdir -p "${XBB_GCC_FOLDER}-mingw-build"
  pushd "${XBB_GCC_FOLDER}-mingw-build"
  (
    export PATH="${XBB}/bin":${PATH}
    export CFLAGS="${CFLAGS} -Wno-sign-compare -Wno-implicit-function-declaration -Wno-missing-prototypes"
    export CXXFLAGS="${CXXFLAGS} -Wno-sign-compare"

    # For the native build, --disable-shared failed with errors in libstdc++-v3
    "${XBB_BUILD}/${XBB_GCC_FOLDER}/configure" --prefix="${XBB}" \
      --prefix="${XBB}" \
      --with-sysroot="${XBB}" \
      --target=${mingw_target} \
      --enable-languages=c,c++ \
      --enable-static \
      --disable-multilib

    make all-gcc -j${MAKE_CONCURRENCY}
    make install-gcc
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r

  echo
  echo "Building mingw-w64 crt ${XBB_MINGW_VERSION}..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_MINGW_ARCHIVE}" "${XBB_MINGW_URL}"

  mkdir -p "${XBB_MINGW_FOLDER}-crt-build"
  pushd "${XBB_MINGW_FOLDER}-crt-build"
  (
    export PATH="${XBB}/bin":${PATH}
    export CFLAGS="-g -O2 -Wno-unused-variable -Wno-implicit-fallthrough -Wno-implicit-function-declaration -Wno-cpp"
    export CXXFLAGS="-g -O2"
    export LDFLAGS=""

    "${XBB_BUILD}/${XBB_MINGW_FOLDER}/configure" \
      --prefix="${XBB}/${mingw_target}" \
      --with-sysroot="${XBB}" \
      --host="${mingw_target}" \
      --disable-lib32 \
      --enable-lib64

    make -j${MAKE_CONCURRENCY}
    make install-strip

    ls -l "${XBB}" "${XBB}/${mingw_target}"
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r

  echo
  echo "Building mingw-w64 gcc ${XBB_GCC_VERSION}, step 2..."
  cd "${XBB_BUILD}"

  # download_and_extract "${XBB_GCC_ARCHIVE}" "${XBB_GCC_URL}"

  mkdir -p "${XBB_GCC_FOLDER}-mingw-build"
  pushd "${XBB_GCC_FOLDER}-mingw-build"
  (
    export PATH="${XBB}/bin":${PATH}
    export CFLAGS="${CFLAGS} -Wno-sign-compare -Wno-implicit-function-declaration -Wno-missing-prototypes"
    export CXXFLAGS="${CXXFLAGS} -Wno-sign-compare"

    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r

fi

# -----------------------------------------------------------------------------

if ! eval_bool "${SKIP_TEXLIVE}"
then
  echo
  echo "Installing texlive.."
  cd "${XBB_BUILD}"

  # https://www.tug.org/texlive/acquire-netinstall.html

  XBB_TEXLIVE_FOLDER="install-tl"
  XBB_TEXLIVE_ARCHIVE="install-tl-unx.tar.gz"
  XBB_TEXLIVE_URL="ftp://tug.org/historic/systems/texlive/2016/${XBB_TEXLIVE_ARCHIVE}"
  XBB_TEXLIVE_PREFIX="/opt/texlive"

  XBB_TEXLIVE_REPO_URL="ftp://tug.org/historic/systems/texlive//2016/tlnet-final"

  download "${XBB_TEXLIVE_ARCHIVE}" "${XBB_TEXLIVE_URL}"

# Create the texlive.profile used to automate the install.
# These definitions are specific to TeX Live 2016.
tmp_profile=$(mktemp)

# Note: __EOF__ is not quoted to allow local substitutions.
cat <<__EOF__ >> "${tmp_profile}"
# texlive.profile, copied from MacTex
TEXDIR ${XBB_TEXLIVE_PREFIX}
TEXMFCONFIG ~/.texlive/texmf-config
TEXMFHOME ~/texmf
TEXMFLOCAL ${XBB_TEXLIVE_PREFIX}/texmf-local
TEXMFSYSCONFIG ${XBB_TEXLIVE_PREFIX}/texmf-config
TEXMFSYSVAR ${XBB_TEXLIVE_PREFIX}/texmf-var
TEXMFVAR ~/.texlive/texmf-var
# binary_universal-darwin 1
binary_universal-darwin 0
binary_x86_64-darwin 1
collection-basic 1
collection-bibtexextra 1
collection-binextra 1
collection-context 1
collection-fontsextra 1
collection-fontsrecommended 1
collection-fontutils 1
collection-formatsextra 1
collection-games 1
collection-genericextra 1
collection-genericrecommended 1
collection-htmlxml 1
collection-humanities 1
collection-langafrican 1
collection-langarabic 1
collection-langchinese 1
collection-langcjk 1
collection-langcyrillic 1
collection-langczechslovak 1
collection-langenglish 1
collection-langeuropean 1
collection-langfrench 1
collection-langgerman 1
collection-langgreek 1
collection-langindic 1
collection-langitalian 1
collection-langjapanese 1
collection-langkorean 1
collection-langother 1
collection-langpolish 1
collection-langportuguese 1
collection-langspanish 1
collection-latex 1
collection-latexextra 1
collection-latexrecommended 1
collection-luatex 1
collection-mathextra 1
collection-metapost 1
collection-music 1
collection-omega 1
collection-pictures 1
collection-plainextra 1
collection-pstricks 1
collection-publishers 1
collection-science 1
collection-texworks 1
collection-xetex 1
in_place 0
option_adjustrepo 0
option_autobackup 1
option_backupdir tlpkg/backups
option_desktop_integration 1
option_doc 1
option_file_assocs 1
option_fmt 1
option_letter 1
option_menu_integration 1
option_path 0
option_post_code 1
option_src 1
option_sys_bin /usr/local/bin
option_sys_info /usr/local/share/info
option_sys_man /usr/local/share/man
option_w32_multi_user 1
option_write18_restricted 1
portable 0
__EOF__

  mkdir -p "${XBB_TEXLIVE_FOLDER}"
  pushd "${XBB_TEXLIVE_FOLDER}"
  (
    tar x -v --strip-components 1 -f "${XBB_DOWNLOAD}/${XBB_TEXLIVE_ARCHIVE}"

    ls -lL

    mkdir -p "${XBB_TEXLIVE_PREFIX}"

    export PATH="${XBB}/bin":${PATH}

    "./install-tl" \
      -repository "${XBB_TEXLIVE_REPO_URL}" \
      -no-gui \
      -lang en \
      -profile "${tmp_profile}"
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r

fi

# rm -rf "${XBB_DOWNLOAD}"
# rm -rf "${XBB_BOOTSTARP}"
rm -rf "${XBB_BUILD}"
rm -rf "${XBB_TMP}"
rm -rf "${XBB_INPUT}"