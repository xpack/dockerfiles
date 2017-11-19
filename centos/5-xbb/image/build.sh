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
# Building the newest tools on CentOS 5 directly is not possible,
# since some of the new tools are not very happy with GCC 4.1.
# So an intermediate solution is used, which includes the most 
# recent versions that can be build with GCC 4.1.
# These intermediate versions are here used to build the 
# final tools.

# Header files have been installed in:
#    /opt/xbb/include

# Libraries have been installed in:
#    /opt/xbb/lib
# 
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

# Use `-fgnu89-inline` to avoid the 'old glibc with new gcc' bug.
# https://github.com/jedisct1/libsodium/issues/202

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

function xbb_activate_param()
{
  PREFIX_=${PREFIX_:-${XBB}}

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

  export CPPFLAGS=-I"${PREFIX_}/include"
  export LDPATHFLAGS="-L\"${PREFIX_}/lib\" ${EXTRA_LDPATHFLAGS_}"

  # Do not include -I... here, use CPPFLAGS.
  local MINIMAL_CFLAGS_="-g -O2"

  export CFLAGS="${MINIMAL_CFLAGS_} ${EXTRA_CFLAGS_}"
	export CXXFLAGS="${MINIMAL_CFLAGS_} ${EXTRA_CXXFLAGS_}"
  export LDFLAGS="${LDPATHFLAGS} ${EXTRA_LDFLAGS_}"

	export STATICLIB_CFLAGS="${MINIMAL_CFLAGS_} ${EXTRA_STATICLIB_CFLAGS_}"
	export STATICLIB_CXXFLAGS="${MINIMAL_CFLAGS_} ${EXTRA_STATICLIB_CXXFLAGS_}"

	export SHLIB_CFLAGS="${MINIMAL_CFLAGS_} ${EXTRA_SHLIB_CFLAGS_}"
	export SHLIB_CXXFLAGS="${MINIMAL_CFLAGS_} ${EXTRA_SHLIB_CXXFLAGS_}"
  export SHLIB_LDFLAGS="${LDPATHFLAGS} ${EXTRA_SHLIB_LDFLAGS_}"
}

xbb_activate()
{
  PREFIX_="${XBB}"
  EXTRA_CFLAGS_="-ffunction-sections -fdata-sections"
  EXTRA_LDFLAGS_="-Wl,--gc-sections"
  EXTRA_STATICLIB_CFLAGS_="-ffunction-sections -fdata-sections"

  xbb_activate_param 
}

xbb_activate_static()
{
  PREFIX_="${XBB}"
  EXTRA_CFLAGS_="-ffunction-sections -fdata-sections"
  EXTRA_LDFLAGS_="-static-libstdc++ -Wl,--gc-sections"
  EXTRA_STATICLIB_CFLAGS_="-ffunction-sections -fdata-sections"
  EXTRA_SHLIB_LDFLAGS_="-static-libstdc++"

  xbb_activate_param 
}

__EOF__
# The above marker must start in the first column.

# -----------------------------------------------------------------------------

# Use the bootstrap tools.
source "${XBB_BOOTSTRAP}/xbb.sh"

xbb_activate_bootstrap()
{
  PREFIX_="${XBB_BOOTSTRAP}"
  # Use `-fgnu89-inline` to avoid the 'old glibc with new gcc' bug
  # https://github.com/jedisct1/libsodium/issues/202
  EXTRA_CFLAGS_="-ffunction-sections -fdata-sections -fgnu89-inline"
  EXTRA_CXXFLAGS_="-ffunction-sections -fdata-sections "
  EXTRA_LDFLAGS_="-static-libstdc++ -Wl,--gc-sections -Wl,-rpath,\"${XBB}/lib\""
  EXTRA_STATICLIB_CFLAGS_="-ffunction-sections -fdata-sections -fgnu89-inline"
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

# SKIP_M4=true
# SKIP_GAWK=true
# SKIP_AUTOCONF=true
# SKIP_AUTOMAKE=true
# SKIP_LIBTOOL=true
# SKIP_GETTEXT=true
# SKIP_PATCH=true
# SKIP_DIFUTILS=true
# SKIP_BISON=true

# SKIP_PKG_CONFIG=true
# SKIP_FLEX=true
# SKIP_PERL=true

# SKIP_CMAKE=true
# SKIP_PYTHON=true

# SKIP_GMP=true
# SKIP_MPFR=true
# SKIP_MPC=true
# SKIP_ISL=true

# SKIP_BINUTILS=true
SKIP_GCC=true

# -----------------------------------------------------------------------------

# Defaults

SKIP_ALL=${SKIP_ALL:-false}

SKIP_ZLIB=${SKIP_ZLIBL:-$SKIP_ALL}
SKIP_OPENSSL=${SKIP_OPENSSL:-$SKIP_ALL}
SKIP_CURL=${SKIP_CURL:-$SKIP_ALL}

SKIP_XZ=${SKIP_XZ:-$SKIP_ALL}
SKIP_TAR=${SKIP_TAR:-$SKIP_ALL}

SKIP_M4=${SKIP_M4:-$SKIP_ALL}
SKIP_GAWK=${SKIP_GAWK:-$SKIP_ALL}
SKIP_AUTOCONF=${SKIP_AUTOCONF:-$SKIP_ALL}
SKIP_AUTOMAKE=${SKIP_AUTOMAKE:-$SKIP_ALL}
SKIP_LIBTOOL=${SKIP_LIBTOOL:-$SKIP_ALL}
SKIP_GETTEXT=${SKIP_GETTEXT:-$SKIP_ALL}
SKIP_PATCH=${SKIP_PATCH:-$SKIP_ALL}
SKIP_DIFFUTILS=${SKIP_DIFFUTILS:-$SKIP_ALL}
SKIP_BISON=${SKIP_BISON:-$SKIP_ALL}

SKIP_PKG_CONFIG=${SKIP_PKG_CONFIG:-$SKIP_ALL}
SKIP_FLEX=${SKIP_FLEX:-$SKIP_ALL}
SKIP_PERL=${SKIP_PERL:-$SKIP_ALL}

SKIP_CMAKE=${SKIP_CMAKE:-$SKIP_ALL}
SKIP_PYTHON=${SKIP_PYTHON:-$SKIP_ALL}

SKIP_GMP=${SKIP_GMP:-$SKIP_ALL}
SKIP_MPFR=${SKIP_MPFR:-$SKIP_ALL}
SKIP_MPC=${SKIP_MPC:-$SKIP_ALL}
SKIP_ISL=${SKIP_ISL:-$SKIP_ALL}

SKIP_BINUTILS=${SKIP_BINUTILS:-$SKIP_ALL}

SKIP_GCC=${SKIP_GCC:-$SKIP_ALL}

# -----------------------------------------------------------------------------

# SKIP_ZLIB=false
# SKIP_OPENSSL=false
# SKIP_CURL=false

# SKIP_XZ=false
# SKIP_TAR=false

# SKIP_M4=false
# SKIP_GAWK=false
# SKIP_AUTOCONF=false
# SKIP_AUTOMAKE=false
# SKIP_LIBTOOL=false
# SKIP_GETTEXT=false
# SKIP_PATCH=false
# SKIP_DIFUTILS=false
# SKIP_BISON=false

# SKIP_PKG_CONFIG=false
# SKIP_FLEX=false
# SKIP_PERL=false

# SKIP_CMAKE=false
# SKIP_PYTHON=false

# SKIP_GMP=false
# SKIP_MPFR=false
# SKIP_MPC=false
# SKIP_ISL=false

# SKIP_BINUTILS=false
# SKIP_GCC=false

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
XBB_CMAKE_VERSION="3.9.6"
XBB_CMAKE_MAJOR_VERSION="3.9"
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

# https://gmplib.org
# https://gmplib.org/download/gmp/
# 16-Dec-2016
XBB_GMP_VERSION="6.1.2"
XBB_GMP_FOLDER="gmp-${XBB_GMP_VERSION}"
XBB_GMP_ARCHIVE="${XBB_GMP_FOLDER}.tar.xz"
XBB_GMP_URL="https://gmplib.org/download/gmp/${XBB_GMP_ARCHIVE}"

# http://www.mpfr.org
# http://www.mpfr.org/mpfr-3.1.6/mpfr-3.1.6.tar.bz2
# 7 September 2017
XBB_MPFR_VERSION="3.1.6"
XBB_MPFR_FOLDER="mpfr-${XBB_MPFR_VERSION}"
XBB_MPFR_ARCHIVE="${XBB_MPFR_FOLDER}.tar.xz"
XBB_MPFR_URL="http://www.mpfr.org/${XBB_MPFR_FOLDER}/${XBB_MPFR_ARCHIVE}"

# http://www.multiprecision.org/
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

function extract()
{
  local ARCHIVE_NAME="$1"

  if [[ "${ARCHIVE_NAME}" =~ '\.bz2$' ]]; then
    tar xjf "${ARCHIVE_NAME}"
  elif [[ "${ARCHIVE_NAME}" =~ '\.xz$' ]]; then
    tar xJf "${ARCHIVE_NAME}"
  else
    tar xzf "${ARCHIVE_NAME}"
  fi
}

function download_and_extract()
{
  local ARCHIVE_NAME="$1"
  local URL="$2"

  if [[ ! -f "${XBB_DOWNLOAD}/${ARCHIVE_NAME}" ]]; then
    rm -f "${XBB_DOWNLOAD}/${ARCHIVE_NAME}.download"
    curl --fail -L -o "${XBB_DOWNLOAD}/${ARCHIVE_NAME}.download" "${URL}"
    mv "${XBB_DOWNLOAD}/${ARCHIVE_NAME}.download" "${XBB_DOWNLOAD}/${ARCHIVE_NAME}"
  fi

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
# Generally build only the static versions of the libraries.
# (the exception are libcrypto.so libcurl.so libssl.so)

if ! eval_bool "${SKIP_ZLIB}"; then
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

# On CentOS 5:
# engines/afalg/e_afalg.c:30:4: warning: #warning "AFALG ENGINE requires Kernel Headers >= 4.1.0" [-Wcpp]

if ! eval_bool "${SKIP_OPENSSL}"
then
  echo "Building openssl ${XBB_OPENSSL_VERSION}..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_OPENSSL_ARCHIVE}" "${XBB_OPENSSL_URL}"

  pushd "${XBB_OPENSSL_FOLDER}"
  (
    # OpenSSL already passes optimization flags regardless of CFLAGS
		export CFLAGS=`echo "$STATICLIB_CFLAGS" | sed 's/-O2//'`

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

if ! eval_bool "${SKIP_M4}"
then
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

if ! eval_bool "${SKIP_AUTOCONF}"; then
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

if ! eval_bool "${SKIP_AUTOMAKE}"; then
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

if ! eval_bool "${SKIP_LIBTOOL}"; then
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

if ! eval_bool "${SKIP_GETTEXT}"; then
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

if ! eval_bool "${SKIP_PATCH}"; then
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

if ! eval_bool "${SKIP_DIFFUTILS}"; then
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

if ! eval_bool "${SKIP_BISON}"; then
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

# -----------------------------------------------------------------------------

if ! eval_bool "${SKIP_PKG_CONFIG}"; then
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
if ! eval_bool "${SKIP_FLEX}"; then
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

if ! eval_bool "${SKIP_PERL}"; then
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

if ! eval_bool "${SKIP_CMAKE}"; then
  echo "Installing cmake ${XBB_CMAKE_VERSION}"
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

if ! eval_bool "${SKIP_PYTHON}"; then
  echo "Installing python ${XBB_PYTHON_VERSION}"
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

# -----------------------------------------------------------------------------

if ! eval_bool "${SKIP_GMP}"; then
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

if ! eval_bool "${SKIP_MPFR}"; then
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

if ! eval_bool "${SKIP_MPC}"; then
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

if ! eval_bool "${SKIP_ISL}"; then
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

if ! eval_bool "${SKIP_BINUTILS}"; then
  echo "Building binutils ${XBB_BINUTILS_VERSION}..."
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_BINUTILS_ARCHIVE}" "${XBB_BINUTILS_URL}"

  pushd "${XBB_BINUTILS_FOLDER}"
  (
    export CFLAGS="${CFLAGS} -Wno-sign-compare"

    ./configure --prefix="${XBB}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

# -----------------------------------------------------------------------------

if ! eval_bool "${SKIP_GCC}"
then
  echo "Building gcc ${XBB_GCC_VERSION}..."
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

# rm -rf "${XBB_DOWNLOAD}"
# rm -rf "${XBB_BOOTSTARP}"
rm -rf "${XBB_BUILD}"
rm -rf "${XBB_TMP}"
rm -rf "${XBB_INPUT}"