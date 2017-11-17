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

# Inspired by Holy Build Box build script.

XBB_INPUT=/xbb-input
XBB_DOWNLOAD="/tmp/xbb-download"
XBB_TMP=/tmp/xbb

XBB_BOOTSTRAP="/opt/xbb-bootstrap"
XBB_BOOTSTRAP_BUILD="${XBB_TMP}/bootstrap-build"

# This is the final location of the tools. Not yet used.
XBB="/opt/xbb"
XBB_BUILD="${XBB_TMP}/xbb-build"

MAKE_CONCURRENCY=2

# -----------------------------------------------------------------------------
# The first step is to build a curl, that understands https.
# This requires openssl.

# https://www.openssl.org
# https://www.openssl.org/source/
# 2017-Jan-26 OK
# XBB_OPENSSL_VERSION=1.0.2k
# 2017-Nov-02 OK
XBB_OPENSSL_VERSION="1.0.2m"
# 2017-Nov-02 Fails with 'Perl v5.10.0 required--this is only v5.8.8' 
# XBB_OPENSSL_VERSION=1.1.0g
XBB_OPENSSL_FOLDER="openssl-${XBB_OPENSSL_VERSION}"
XBB_OPENSSL_ARCHIVE="${XBB_OPENSSL_FOLDER}.tar.gz"
# No URL; passed via $XBB_INPUT, CentOS 5 curl cannot access https.

# https://curl.haxx.se
# https://curl.haxx.se/download/
# 2017-04-19 OK
XBB_CURL_VERSION="7.54.0"
# 2017-06-14 Fails with 'configure.ac:54: warning: AC_PROG_SED is m4_require'd but is not m4_defun'd'
# XBB_CURL_VERSION=7.54.1
# 2017-08-14 Fails with 'configure.ac:54: warning: AC_PROG_SED is m4_require'd but is not m4_defun'd'
# XBB_CURL_VERSION=7.55.1
# 2017-10-23 Fails with 'configure.ac:54: warning: AC_PROG_SED is m4_require'd but is not m4_defun'd'
# XBB_CURL_VERSION=7.56.1
XBB_CURL_FOLDER="curl-${XBB_CURL_VERSION}"
XBB_CURL_ARCHIVE="${XBB_CURL_FOLDER}.tar.bz2"
# No URL, passed via $XBB_INPUT, CentOS 5 curl cannot access https.

# -----------------------------------------------------------------------------
# The second step is to build a new tar, that understand xz.
# This requires the xz libraries.

# https://tukaani.org/xz/
# https://sourceforge.net/projects/lzmautils/files/
# 2016-12-30
XBB_XZ_VERSION="5.2.3"
XBB_XZ_FOLDER="xz-${XBB_XZ_VERSION}"
XBB_XZ_ARCHIVE="${XBB_XZ_FOLDER}.tar.bz2"
XBB_XZ_URL="https://sourceforge.net/projects/lzmautils/files/${XBB_XZ_ARCHIVE}"

# https://www.gnu.org/software/tar/
# https://ftp.gnu.org/gnu/tar/
# 2016-05-16
XBB_TAR_VERSION="1.29"
XBB_TAR_FOLDER="tar-${XBB_TAR_VERSION}"
XBB_TAR_ARCHIVE="${XBB_TAR_FOLDER}.tar.bz2"
XBB_TAR_URL="https://ftp.gnu.org/gnu/tar/${XBB_TAR_ARCHIVE}"

# -----------------------------------------------------------------------------
# Build GNU tools. From now, xz is available.

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
# XBB_PKG_CONFIG_VERSION=0.29.1
XBB_PKG_CONFIG_VERSION="0.29.2"
XBB_PKG_CONFIG_FOLDER="pkg-config-${XBB_PKG_CONFIG_VERSION}"
XBB_PKG_CONFIG_ARCHIVE="${XBB_PKG_CONFIG_FOLDER}.tar.gz"
XBB_PKG_CONFIG_URL="https://pkgconfig.freedesktop.org/releases/${XBB_PKG_CONFIG_ARCHIVE}"

# https://github.com/westes/flex
# https://github.com/westes/flex/releases
XBB_FLEX_VERSION="2.6.4"
XBB_FLEX_FOLDER="flex-${XBB_FLEX_VERSION}"
XBB_FLEX_ARCHIVE="${XBB_FLEX_FOLDER}.tar.gz"
XBB_FLEX_URL="https://github.com/westes/flex/releases/download/v${XBB_FLEX_VERSION}/${XBB_FLEX_ARCHIVE}"

# https://www.cpan.org
# http://www.cpan.org/src/
XBB_PERL_MAJOR_VERSION="5.0"
XBB_PERL_VERSION="5.24.1"
# Fails with undefined reference to `Perl_fp_class_denorm'
# XBB_PERL_VERSION="5.26.1"
XBB_PERL_FOLDER="perl-${XBB_PERL_VERSION}"
XBB_PERL_ARCHIVE="${XBB_PERL_FOLDER}.tar.gz"
XBB_PERL_URL="http://www.cpan.org/src/${XBB_PERL_MAJOR_VERSION}/${XBB_PERL_ARCHIVE}"

# https://cmake.org/download/
# XBB_CMAKE_VERSION=3.6.3
XBB_CMAKE_VERSION=3.9.6
# XBB_CMAKE_MAJOR_VERSION=3.6
XBB_CMAKE_MAJOR_VERSION=3.9
XBB_CMAKE_FOLDER="cmake-${XBB_CMAKE_VERSION}"
XBB_CMAKE_ARCHIVE="${XBB_CMAKE_FOLDER}.tar.gz"
XBB_CMAKE_URL="https://cmake.org/files/v${XBB_CMAKE_MAJOR_VERSION}/${XBB_CMAKE_ARCHIVE}"

# https://www.python.org/downloads/source/
# XBB_PYTHON_VERSION=2.7.12
XBB_PYTHON_VERSION=2.7.14
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

XBB_GCC_VERSION="7.2.0"
XBB_GCC_FOLDER="gcc-${XBB_GCC_VERSION}"
XBB_GCC_ARCHIVE="${XBB_GCC_FOLDER}.tar.xz"
XBB_GCC_URL="https://ftp.gnu.org/gnu/gcc/gcc-${XBB_GCC_VERSION}/${XBB_GCC_ARCHIVE}"

# -----------------------------------------------------------------------------

# SKIP_BOOTSTRAP=true

# SKIP_BOOTSTRAP_OPENSSL=true
# SKIP_BOOTSTRAP_CURL=true
# SKIP_BOOTSTRAP_XZ=true
# SKIP_BOOTSTRAP_TAR=true

# SKIP_BOOTSTRAP_M4=true
# SKIP_BOOTSTRAP_GAWK=true
# SKIP_BOOTSTRAP_AUTOCONF=true
# SKIP_BOOTSTRAP_AUTOMAKE=true
# SKIP_BOOTSTRAP_LIBTOOL=true
# SKIP_BOOTSTRAP_GETTEXT=true
# SKIP_BOOTSTRAP_PATCH=true
# SKIP_BOOTSTRAP_DIFUTILS=true
# SKIP_BOOTSTRAP_BISON=true

# SKIP_BOOTSTRAP_PKG_CONFIG=true
# SKIP_BOOTSTRAP_FLEX=true
# SKIP_BOOTSTRAP_PERL=true

# SKIP_BOOTSTRAP_CMAKE=true
# SKIP_BOOTSTRAP_PYTHON=true

# SKIP_BOOTSTRAP_GMP=true
# SKIP_BOOTSTRAP_MPFR=true
# SKIP_BOOTSTRAP_MPC=true
# SKIP_BOOTSTRAP_ISL=true

# SKIP_BOOTSTRAP_BINUTILS=true
# SKIP_BOOTSTRAP_GCC=true

# -----------------------------------------------------------------------------

# Defaults

SKIP_BOOTSTRAP=${SKIP_BOOTSTRAP:-false}

SKIP_BOOTSTRAP_OPENSSL=${SKIP_BOOTSTRAP_OPENSSL:-$SKIP_BOOTSTRAP}
SKIP_BOOTSTRAP_CURL=${SKIP_BOOTSTRAP_CURL:-$SKIP_BOOTSTRAP}

SKIP_BOOTSTRAP_XZ=${SKIP_BOOTSTRAP_XZ:-$SKIP_BOOTSTRAP}
SKIP_BOOTSTRAP_TAR=${SKIP_BOOTSTRAP_TAR:-$SKIP_BOOTSTRAP}

SKIP_BOOTSTRAP_M4=${SKIP_BOOTSTRAP_M4:-$SKIP_BOOTSTRAP}
SKIP_BOOTSTRAP_GAWK=${SKIP_BOOTSTRAP_GAWK:-$SKIP_BOOTSTRAP}
SKIP_BOOTSTRAP_AUTOCONF=${SKIP_BOOTSTRAP_AUTOCONF:-$SKIP_BOOTSTRAP}
SKIP_BOOTSTRAP_AUTOMAKE=${SKIP_BOOTSTRAP_AUTOMAKE:-$SKIP_BOOTSTRAP}
SKIP_BOOTSTRAP_LIBTOOL=${SKIP_BOOTSTRAP_LIBTOOL:-$SKIP_BOOTSTRAP}
SKIP_BOOTSTRAP_GETTEXT=${SKIP_BOOTSTRAP_GETTEXT:-$SKIP_BOOTSTRAP}
SKIP_BOOTSTRAP_PATCH=${SKIP_BOOTSTRAP_PATCH:-$SKIP_BOOTSTRAP}
SKIP_BOOTSTRAP_DIFFUTILS=${SKIP_BOOTSTRAP_DIFFUTILS:-$SKIP_BOOTSTRAP}
SKIP_BOOTSTRAP_BISON=${SKIP_BOOTSTRAP_BISON:-$SKIP_BOOTSTRAP}

SKIP_BOOTSTRAP_PKG_CONFIG=${SKIP_BOOTSTRAP_PKG_CONFIG:-$SKIP_BOOTSTRAP}
SKIP_BOOTSTRAP_FLEX=${SKIP_BOOTSTRAP_FLEX:-$SKIP_BOOTSTRAP}
SKIP_BOOTSTRAP_PERL=${SKIP_BOOTSTRAP_PERL:-$SKIP_BOOTSTRAP}

SKIP_BOOTSTRAP_CMAKE=${SKIP_BOOTSTRAP_CMAKE:-$SKIP_BOOTSTRAP}
SKIP_BOOTSTRAP_PYTHON=${SKIP_BOOTSTRAP_PYTHON:-$SKIP_BOOTSTRAP}

SKIP_BOOTSTRAP_GMP=${SKIP_BOOTSTRAP_GMP:-$SKIP_BOOTSTRAP}
SKIP_BOOTSTRAP_MPFR=${SKIP_BOOTSTRAP_MPFR:-$SKIP_BOOTSTRAP}
SKIP_BOOTSTRAP_MPC=${SKIP_BOOTSTRAP_MPC:-$SKIP_BOOTSTRAP}
SKIP_BOOTSTRAP_ISL=${SKIP_BOOTSTRAP_ISL:-$SKIP_BOOTSTRAP}

SKIP_BOOTSTRAP_BINUTILS=${SKIP_BOOTSTRAP_BINUTILS:-$SKIP_BOOTSTRAP}

SKIP_BOOTSTRAP_GCC=${SKIP_BOOTSTRAP_GCC:-$SKIP_BOOTSTRAP}

# -----------------------------------------------------------------------------

function extract()
{
  local ARCHIVE_NAME="$1"

  if [[ "${ARCHIVE_NAME}" =~ '\.bz2$' ]]; then
    tar xjf "${ARCHIVE_NAME}"
  elif [[ "${ARCHIVE_NAME}" =~ '\.xz$' ]]; then
    (
      # For xz, use the bootstrap tar
      PATH="${XBB_BOOTSTRAP}/bin":${PATH}
      tar xJf "${ARCHIVE_NAME}"
    )
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
    "${XBB_BOOTSTRAP}/bin/curl" --fail -L -o "${XBB_DOWNLOAD}/${ARCHIVE_NAME}.download" "${URL}"
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

mkdir -p "${XBB}"

mkdir -p "${XBB_TMP}"
mkdir -p "${XBB_DOWNLOAD}"
mkdir -p "${XBB_BUILD}"

mkdir -p "${XBB_BOOTSTRAP}"
mkdir -p "${XBB_BOOTSTRAP_BUILD}"

# -----------------------------------------------------------------------------

# Note: __EOF__ is quoted to prevent substitutions here.
cat <<'__EOF__' >> "${XBB_BOOTSTRAP}/xbb.sh"

# $1=path ($XBB_BOOTSTRAP)
function xbb_activate()
{
  local BB_
  if [ $# -gt 0 ]
  then
    BB_=$1
  else
    BB_="${XBB_BOOTSTRAP}"
  fi
  export PATH="${BB_}/bin":${PATH}
  export C_INCLUDE_PATH="${BB_}/include"
  export CPLUS_INCLUDE_PATH="${BB_}/include"
  export LIBRARY_PATH="${BB_}/lib"
  export PKG_CONFIG_PATH="${BB_}/lib/pkgconfig":/usr/lib/pkgconfig
  export CPPFLAGS=-I"${BB_}/include"
  export LDPATHFLAGS="-L\"${BB_}/lib\" -Wl,-rpath,\"${BB_}/lib\""
  export LDFLAGS="${LDPATHFLAGS}"
  export LD_LIBRARY_PATH="${BB_}/lib"
}

__EOF__
# The above marker must start in the first column.

source "${XBB_BOOTSTRAP}/xbb.sh"

# -----------------------------------------------------------------------------
# WARNING: the order is important, since some of the builds depend
# on previous ones.
# For extra safety, the ${XBB_BOOTSTRAP} is not permanently in PATH,
# it is added explicitly with xbb_activate in sub-shells.
# Generally build only the static versions of the libraries.
# (the exception are libcrypto.so libcurl.so libssl.so)

if ! eval_bool "${SKIP_BOOTSTRAP_OPENSSL}"
then
  echo "Building bootstrap openssl ${XBB_OPENSSL_VERSION}..."
  cd "${XBB_BOOTSTRAP_BUILD}"

  extract "${XBB_INPUT}/${XBB_OPENSSL_ARCHIVE}" 

  pushd "${XBB_OPENSSL_FOLDER}"
  (
    xbb_activate

    ./config --prefix="${XBB_BOOTSTRAP}" --openssldir="${XBB_BOOTSTRAP}/openssl" \
      threads zlib shared
    make
    make install_sw

    strip --strip-all "${XBB_BOOTSTRAP}/bin/openssl"
    strip --strip-debug "${XBB_BOOTSTRAP}/lib/libssl.so" \
      "${XBB_BOOTSTRAP}/lib/libcrypto.so"
    rm -f "${XBB_BOOTSTRAP}/lib/libssl.a" "${XBB_BOOTSTRAP}/lib/libcrypto.a"
    ln -s /etc/pki/tls/certs/ca-bundle.crt "${XBB_BOOTSTRAP}/openssl/cert.pem"
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd
fi

if ! eval_bool "${SKIP_BOOTSTRAP_CURL}"
then
  echo "Building bootstrap curl ${XBB_CURL_VERSION}..."
  cd "${XBB_BOOTSTRAP_BUILD}"

  extract "${XBB_INPUT}/${XBB_CURL_ARCHIVE}" 

  pushd "${XBB_CURL_FOLDER}"
  (
    xbb_activate

    ./buildconf
    ./configure --prefix="${XBB_BOOTSTRAP}" --disable-static --disable-debug \
      --enable-optimize --disable-manual --with-ssl \
      --with-ca-bundle=/etc/pki/tls/certs/ca-bundle.crt
    make -j${MAKE_CONCURRENCY}
    make install

    strip --strip-all "${XBB_BOOTSTRAP}/bin/curl"
    strip --strip-debug "${XBB_BOOTSTRAP}/lib/libcurl.so"
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

# -----------------------------------------------------------------------------

if ! eval_bool "${SKIP_BOOTSTRAP_XZ}"
then
  echo "Building bootstrap xz ${XBB_XZ_VERSION}..."
  cd "${XBB_BOOTSTRAP_BUILD}"

  download_and_extract "${XBB_XZ_ARCHIVE}" "${XBB_XZ_URL}"

  pushd "${XBB_XZ_FOLDER}"
  (
    xbb_activate

    ./configure --prefix="${XBB_BOOTSTRAP}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

# Requires xz
if ! eval_bool "${SKIP_BOOTSTRAP_TAR}"
then
  echo "Building bootstrap tar ${XBB_TAR_VERSION}..."
  cd "${XBB_BOOTSTRAP_BUILD}"

  download_and_extract "${XBB_TAR_ARCHIVE}" "${XBB_TAR_URL}"

  pushd "${XBB_TAR_FOLDER}"
  (
    xbb_activate

    export FORCE_UNSAFE_CONFIGURE=1
    ./configure --prefix="${XBB_BOOTSTRAP}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

# -----------------------------------------------------------------------------

if ! eval_bool "${SKIP_BOOTSTRAP_M4}"
then
  echo "Building bootstrap m4 ${XBB_M4_VERSION}..."
  cd "${XBB_BOOTSTRAP_BUILD}"

  download_and_extract "${XBB_M4_ARCHIVE}" "${XBB_M4_URL}"

  pushd "${XBB_M4_FOLDER}"
  (
    xbb_activate

    ./configure --prefix="${XBB_BOOTSTRAP}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

if ! eval_bool "${SKIP_BOOTSTRAP_GAWK}"
then
  echo "Building bootstrap gawk ${XBB_GAWK_VERSION}..."
  cd "${XBB_BOOTSTRAP_BUILD}"

  download_and_extract "${XBB_GAWK_ARCHIVE}" "${XBB_GAWK_URL}"

  pushd "${XBB_GAWK_FOLDER}"
  (
    xbb_activate

    ./configure --prefix="${XBB_BOOTSTRAP}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

if ! eval_bool "${SKIP_BOOTSTRAP_AUTOCONF}"; then
  echo "Building bootstrap autoconf ${XBB_AUTOCONF_VERSION}..."
  cd "${XBB_BOOTSTRAP_BUILD}"

  download_and_extract "${XBB_AUTOCONF_ARCHIVE}" "${XBB_AUTOCONF_URL}"

  pushd "${XBB_AUTOCONF_FOLDER}"
  (
    xbb_activate

    ./configure --prefix="${XBB_BOOTSTRAP}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

if ! eval_bool "${SKIP_BOOTSTRAP_AUTOMAKE}"; then
  echo "Building bootstrap automake ${XBB_AUTOMAKE_VERSION}..."
  cd "${XBB_BOOTSTRAP_BUILD}"

  download_and_extract "${XBB_AUTOMAKE_ARCHIVE}" "${XBB_AUTOMAKE_URL}"

  pushd "${XBB_AUTOMAKE_FOLDER}"
  (
    xbb_activate

    ./configure --prefix="${XBB_BOOTSTRAP}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

if ! eval_bool "${SKIP_BOOTSTRAP_LIBTOOL}"; then
  echo "Building bootstrap libtool ${XBB_LIBTOOL_VERSION}..."
  cd "${XBB_BOOTSTRAP_BUILD}"

  download_and_extract "${XBB_LIBTOOL_ARCHIVE}" "${XBB_LIBTOOL_URL}"

  pushd "${XBB_LIBTOOL_FOLDER}"
  (
    xbb_activate

    ./configure --prefix="${XBB_BOOTSTRAP}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

if ! eval_bool "${SKIP_BOOTSTRAP_GETTEXT}"; then
  echo "Building bootstrap gettext ${XBB_GETTEXT_VERSION}..."
  cd "${XBB_BOOTSTRAP_BUILD}"

  download_and_extract "${XBB_GETTEXT_ARCHIVE}" "${XBB_GETTEXT_URL}"

  pushd "${XBB_GETTEXT_FOLDER}"
  (
    xbb_activate

    ./configure --prefix="${XBB_BOOTSTRAP}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

if ! eval_bool "${SKIP_BOOTSTRAP_PATCH}"; then
  echo "Building bootstrap patch ${XBB_PATCH_VERSION}..."
  cd "${XBB_BOOTSTRAP_BUILD}"

  download_and_extract "${XBB_PATCH_ARCHIVE}" "${XBB_PATCH_URL}"

  pushd "${XBB_PATCH_FOLDER}"
  (
    xbb_activate

    ./configure --prefix="${XBB_BOOTSTRAP}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

if ! eval_bool "${SKIP_BOOTSTRAP_DIFFUTILS}"; then
  echo "Building bootstrap diffutils ${XBB_DIFFUTILS_VERSION}..."
  cd "${XBB_BOOTSTRAP_BUILD}"

  download_and_extract "${XBB_DIFFUTILS_ARCHIVE}" "${XBB_DIFFUTILS_URL}"

  pushd "${XBB_DIFFUTILS_FOLDER}"
  (
    xbb_activate

    ./configure --prefix="${XBB_BOOTSTRAP}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

if ! eval_bool "${SKIP_BOOTSTRAP_BISON}"; then
  echo "Building bootstrap bison ${XBB_BISON_VERSION}..."
  cd "${XBB_BOOTSTRAP_BUILD}"

  download_and_extract "${XBB_BISON_ARCHIVE}" "${XBB_BISON_URL}"

  pushd "${XBB_BISON_FOLDER}"
  (
    xbb_activate

    ./configure --prefix="${XBB_BOOTSTRAP}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

# -----------------------------------------------------------------------------

if ! eval_bool "${SKIP_BOOTSTRAP_PKG_CONFIG}"; then
  echo "Building bootstrap pkg-config ${XBB_PKG_CONFIG_VERSION}..."
  cd "${XBB_BOOTSTRAP_BUILD}"

  download_and_extract "${XBB_PKG_CONFIG_ARCHIVE}" "${XBB_PKG_CONFIG_URL}"

  pushd "${XBB_PKG_CONFIG_FOLDER}"
  (
    xbb_activate

    ./configure --prefix="${XBB_BOOTSTRAP}" --with-internal-glib
    rm -f "${XBB_BOOTSTRAP}/bin"/*pkg-config
    make -j${MAKE_CONCURRENCY} install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

# Requires gettext
if ! eval_bool "${SKIP_BOOTSTRAP_FLEX}"; then
  echo "Building bootstrap flex ${XBB_FLEX_VERSION}..."
  cd "${XBB_BOOTSTRAP_BUILD}"

  download_and_extract "${XBB_FLEX_ARCHIVE}" "${XBB_FLEX_URL}"

  pushd "${XBB_FLEX_FOLDER}"
  (
    xbb_activate

    ./autogen.sh
    ./configure --prefix="${XBB_BOOTSTRAP}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

if ! eval_bool "${SKIP_BOOTSTRAP_PERL}"; then
  echo "Building bootstrap perl ${XBB_PERL_VERSION}..."
  cd "${XBB_BOOTSTRAP_BUILD}"

  download_and_extract "${XBB_PERL_ARCHIVE}" "${XBB_PERL_URL}"

  pushd "${XBB_PERL_FOLDER}"
  (
    xbb_activate

    ./Configure -des -Dprefix="${XBB_BOOTSTRAP}"
    make -j${MAKE_CONCURRENCY}
    make install-strip

    curl -L http://cpanmin.us | perl - App::cpanminus
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

# -----------------------------------------------------------------------------

if ! eval_bool "${SKIP_BOOTSTRAP_CMAKE}"; then
  echo "Installing bootstrap cmake ${XBB_CMAKE_VERSION}"
  cd "${XBB_BOOTSTRAP_BUILD}"

  download_and_extract "${XBB_CMAKE_ARCHIVE}" "${XBB_CMAKE_URL}"

  pushd "${XBB_CMAKE_FOLDER}"
  (
    xbb_activate

    ./configure --prefix="${XBB_BOOTSTRAP}" --no-qt-gui --parallel=${MAKE_CONCURRENCY}
    make -j${MAKE_CONCURRENCY}
    make install
    strip --strip-all ${XBB_BOOTSTRAP}/bin/cmake
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

if ! eval_bool "${SKIP_BOOTSTRAP_PYTHON}"; then
  echo "Installing bootstrap python ${XBB_PYTHON_VERSION}"
  cd "${XBB_BOOTSTRAP_BUILD}"

  download_and_extract "${XBB_PYTHON_ARCHIVE}" "${XBB_PYTHON_URL}"

  pushd "${XBB_PYTHON_FOLDER}"
  (
    xbb_activate

    ./configure --prefix="${XBB_BOOTSTRAP}"
    make -j${MAKE_CONCURRENCY} install
    strip --strip-all "${XBB_BOOTSTRAP}/bin/python"
    strip --strip-debug "${XBB_BOOTSTRAP}"/lib/python*/lib-dynload/*.so
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
 
  (
    xbb_activate

    # Install setuptools and pip
    echo "Installing setuptools and pip..."
    curl -OL --fail https://bootstrap.pypa.io/ez_setup.py
    python ez_setup.py
    rm -f ez_setup.py
    easy_install pip
    rm -f /setuptools*.zip
  )
fi

# -----------------------------------------------------------------------------

if ! eval_bool "${SKIP_BOOTSTRAP_GMP}"; then
  echo "Building bootstrap gmp ${XBB_GMP_VERSION}..."
  cd "${XBB_BOOTSTRAP_BUILD}"

  download_and_extract "${XBB_GMP_ARCHIVE}" "${XBB_GMP_URL}"

  pushd "${XBB_GMP_FOLDER}"
  (
    xbb_activate

    ./configure --prefix="${XBB_BOOTSTRAP}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd
fi

if ! eval_bool "${SKIP_BOOTSTRAP_MPFR}"; then
  echo "Building bootstrap mpfr ${XBB_MPFR_VERSION}..."
  cd "${XBB_BOOTSTRAP_BUILD}"

  download_and_extract "${XBB_MPFR_ARCHIVE}" "${XBB_MPFR_URL}"

  pushd "${XBB_MPFR_FOLDER}"
  (
    xbb_activate "$XBB_BOOTSTRAP"

    ./configure --prefix="${XBB_BOOTSTRAP}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd
fi

if ! eval_bool "${SKIP_BOOTSTRAP_MPC}"; then
  echo "Building bootstrap mpc ${XBB_MPC_VERSION}..."
  cd "${XBB_BOOTSTRAP_BUILD}"

  download_and_extract "${XBB_MPC_ARCHIVE}" "${XBB_MPC_URL}"

  pushd "${XBB_MPC_FOLDER}"
  (
    xbb_activate

    ./configure --prefix="${XBB_BOOTSTRAP}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd
fi

if ! eval_bool "${SKIP_BOOTSTRAP_ISL}"; then
  echo "Building bootstrap isl ${XBB_ISL_VERSION}..."
  cd "${XBB_BOOTSTRAP_BUILD}"

  download_and_extract "${XBB_ISL_ARCHIVE}" "${XBB_ISL_URL}"

  pushd "$XBB_ISL_FOLDER"
  (
    xbb_activate

    ./configure --prefix="${XBB_BOOTSTRAP}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd
fi

if ! eval_bool "${SKIP_BOOTSTRAP_BINUTILS}"; then
  echo "Building bootstrap binutils ${XBB_BINUTILS_VERSION}..."
  cd "${XBB_BOOTSTRAP_BUILD}"

  download_and_extract "${XBB_BINUTILS_ARCHIVE}" "${XBB_BINUTILS_URL}"

  pushd "${XBB_BINUTILS_FOLDER}"
  (
    xbb_activate

    ./configure --prefix="${XBB_BOOTSTRAP}" --disable-shared --enable-static
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi

# -----------------------------------------------------------------------------

if ! eval_bool "${SKIP_BOOTSTRAP_GCC}"
then
  echo "Building bootstrap gcc ${XBB_GCC_VERSION}..."
  cd "${XBB_BOOTSTRAP_BUILD}"

  download_and_extract "${XBB_GCC_ARCHIVE}" "${XBB_GCC_URL}"

  mkdir -p "${XBB_GCC_FOLDER}-build"
  pushd "${XBB_GCC_FOLDER}-build"
  (
    xbb_activate

    # --disable-shared failed with errors in libstdc++-v3
    "../${XBB_GCC_FOLDER}/configure" --prefix="${XBB_BOOTSTRAP}" \
      --enable-languages=c,c++ \
      --disable-multilib
    make -j${MAKE_CONCURRENCY}
    make install-strip
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd
fi

# -----------------------------------------------------------------------------

# rm -rf "$XBB_DOWNLOAD"
rm -rf "$XBB_BOOTSTRAP_BUILD"
rm -rf "$XBB_TMP"
rm -rf "$XBB_INPUT"