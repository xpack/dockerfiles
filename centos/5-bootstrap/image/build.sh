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
XBB_TMP=/tmp/xbb
XBB_DOWNLOAD="${XBB_TMP}/download"

XBB_BOOTSTRAP="/opt/xbb-bootstrap"
XBB_BOOTSTRAP_BUILD="${XBB_TMP}/bootstrap-build"

# This is the final location of the tools.
XBB="/opt/xbb"
XBB_BUILD="${XBB_TMP}/xbb-build"

MAKE_CONCURRENCY=2

# -----------------------------------------------------------------------------

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

# https://ftp.gnu.org/gnu/m4/
# XBB_M4_VERSION=1.4.17
# 2016-12-31
XBB_M4_VERSION="1.4.18"
XBB_M4_FOLDER="m4-${XBB_M4_VERSION}"
XBB_M4_ARCHIVE="${XBB_M4_FOLDER}.tar.bz2"
XBB_M4_URL="https://ftp.gnu.org/gnu/m4/${XBB_M4_ARCHIVE}"

# https://ftp.gnu.org/gnu/gawk/
# 2017-10-19
XBB_GAWK_VERSION="4.2.0"
XBB_GAWK_FOLDER="gawk-${XBB_GAWK_VERSION}"
XBB_GAWK_ARCHIVE="${XBB_GAWK_FOLDER}.tar.gz"
XBB_GAWK_URL="https://ftp.gnu.org/gnu/gawk/${XBB_GAWK_ARCHIVE}"

# https://ftp.gnu.org/gnu/tar/
# 2016-05-16
XBB_TAR_VERSION="1.29"
XBB_TAR_FOLDER="tar-${XBB_TAR_VERSION}"
XBB_TAR_ARCHIVE="${XBB_TAR_FOLDER}.tar.bz2"
XBB_TAR_URL="https://ftp.gnu.org/gnu/tar/${XBB_TAR_ARCHIVE}"

# https://ftp.gnu.org/gnu/autoconf/
# 2012-04-24
XBB_AUTOCONF_VERSION="2.69"
XBB_AUTOCONF_FOLDER="autoconf-${XBB_AUTOCONF_VERSION}"
XBB_AUTOCONF_ARCHIVE="${XBB_AUTOCONF_FOLDER}.tar.gz"
XBB_AUTOCONF_URL="https://ftp.gnu.org/gnu/autoconf/${XBB_AUTOCONF_ARCHIVE}"

# https://ftp.gnu.org/gnu/automake/
# 2015-01-05
XBB_AUTOMAKE_VERSION="1.15"
XBB_AUTOMAKE_FOLDER="automake-${XBB_AUTOMAKE_VERSION}"
XBB_AUTOMAKE_ARCHIVE="${XBB_AUTOMAKE_FOLDER}.tar.gz"
XBB_AUTOMAKE_URL="https://ftp.gnu.org/gnu/automake/${XBB_AUTOMAKE_ARCHIVE}"



# http://gnu.mirrors.linux.ro/libtool/
# 15-Feb-2015
XBB_LIBTOOL_VERSION="2.4.6"
XBB_LIBTOOL_FOLDER="libtool-${XBB_LIBTOOL_VERSION}"
XBB_LIBTOOL_ARCHIVE="${XBB_LIBTOOL_FOLDER}.tar.gz"
XBB_LIBTOOL_URL="http://ftpmirror.gnu.org/libtool/${XBB_LIBTOOL_ARCHIVE}"

# https://pkgconfig.freedesktop.org/releases/
# XBB_PKG_CONFIG_VERSION=0.29.1
XBB_PKG_CONFIG_VERSION="0.29.2"
XBB_PKG_CONFIG_FOLDER="pkg-config-${XBB_PKG_CONFIG_VERSION}"
XBB_PKG_CONFIG_ARCHIVE="${XBB_PKG_CONFIG_FOLDER}.tar.gz"
XBB_PKG_CONFIG_URL="https://pkgconfig.freedesktop.org/releases/${XBB_PKG_CONFIG_ARCHIVE}"

# https://gmplib.org
# https://gmplib.org/download/gmp/
# 16-Dec-2016
XBB_GMP_VERSION="6.1.2"
XBB_GMP_FOLDER="gmp-${XBB_GMP_VERSION}"
XBB_GMP_ARCHIVE="${XBB_GMP_FOLDER}.tar.bz2"
XBB_GMP_URL="https://gmplib.org/download/gmp/${XBB_GMP_ARCHIVE}"

# http://www.mpfr.org
# http://www.mpfr.org/mpfr-3.1.6/mpfr-3.1.6.tar.bz2
# 7 September 2017
XBB_MPFR_VERSION="3.1.6"
XBB_MPFR_FOLDER="mpfr-${XBB_MPFR_VERSION}"
XBB_MPFR_ARCHIVE="${XBB_MPFR_FOLDER}.tar.bz2"
XBB_MPFR_URL="http://www.mpfr.org/${XBB_MPFR_FOLDER}/${XBB_MPFR_ARCHIVE}"

# http://www.multiprecision.org/index.php?prog=mpc
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
XBB_ISL_ARCHIVE="${XBB_ISL_FOLDER}.tar.bz2"
XBB_ISL_URL="http://isl.gforge.inria.fr/${XBB_ISL_ARCHIVE}"

# Other dependencies (from https://gcc.gnu.org/install/prerequisites.html):
#
# Perl version 5.6.1 (or later)
# Flex version 2.5.4 (or later)

# patch version 2.5.4 (or later)
#  2.7 2012-09-12
# GNU diffutils version 2.7 (or later)
#  3.6 2017-05-21

# binutils https://ftp.gnu.org/gnu/binutils/
#   2.29

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

# https://ftp.gnu.org/gnu/binutils/
# 2017-07-24
XBB_BINUTILS_VERSION="2.29"
XBB_BINUTILS_FOLDER="binutils-${XBB_BINUTILS_VERSION}"
XBB_BINUTILS_ARCHIVE="${XBB_BINUTILS_FOLDER}.tar.gz"
XBB_BINUTILS_URL="https://ftp.gnu.org/gnu/binutils/${XBB_BINUTILS_ARCHIVE}"

# -----------------------------------------------------------------------------

# XBB_CCACHE_VERSION=3.3.3
XBB_CMAKE_VERSION=3.6.3
XBB_CMAKE_MAJOR_VERSION=3.6
XBB_PYTHON_VERSION=2.7.12
XBB_GCC_LIBSTDCXX_VERSION=4.8.2
XBB_ZLIB_VERSION=1.2.11

# SKIP_BOOTSTRAP_OPENSSL=true
# SKIP_BOOTSTRAP_CURL=true
# SKIP_BOOTSTRAP_M4=true
# SKIP_BOOTSTRAP_GAWK=true
# SKIP_BOOTSTRAP_TAR=true
# SKIP_BOOTSTRAP_AUTOCONF=true
# SKIP_BOOTSTRAP_AUTOMAKE=true
# SKIP_BOOTSTRAP_LIBTOOL=true
# SKIP_BOOTSTRAP_PKG_CONFIG=true

# SKIP_BOOTSTRAP_GMP=true
# SKIP_BOOTSTRAP_MPFR=true
# SKIP_BOOTSTRAP_MPC=true
# SKIP_BOOTSTRAP_ISL=true

SKIP_CMAKE=true
SKIP_PYTHON=true

# Defaults

SKIP_BOOTSTRAP=${SKIP_BOOTSTRAP:-false}

SKIP_BOOTSTRAP_OPENSSL=${SKIP_BOOTSTRAP_OPENSSL:-$SKIP_BOOTSTRAP}
SKIP_BOOTSTRAP_CURL=${SKIP_BOOTSTRAP_CURL:-$SKIP_BOOTSTRAP}
SKIP_BOOTSTRAP_M4=${SKIP_BOOTSTRAP_M4:-$SKIP_BOOTSTRAP}
SKIP_BOOTSTRAP_GAWK=${SKIP_BOOTSTRAP_GAWK:-$SKIP_BOOTSTRAP}
SKIP_BOOTSTRAP_TAR=${SKIP_BOOTSTRAP_TAR:-$SKIP_BOOTSTRAP}
SKIP_BOOTSTRAP_AUTOCONF=${SKIP_BOOTSTRAP_AUTOCONF:-$SKIP_BOOTSTRAP}
SKIP_BOOTSTRAP_AUTOMAKE=${SKIP_BOOTSTRAP_AUTOMAKE:-$SKIP_BOOTSTRAP}
SKIP_BOOTSTRAP_LIBTOOL=${SKIP_BOOTSTRAP_LIBTOOL:-$SKIP_BOOTSTRAP}
SKIP_BOOTSTRAP_PKG_CONFIG=${SKIP_BOOTSTRAP_PKG_CONFIG:-$SKIP_BOOTSTRAP}

SKIP_BOOTSTRAP_GMP=${SKIP_BOOTSTRAP_GMP:-$SKIP_BOOTSTRAP}
SKIP_BOOTSTRAP_MPFR=${SKIP_BOOTSTRAP_MPFR:-$SKIP_BOOTSTRAP}
SKIP_BOOTSTRAP_MPC=${SKIP_BOOTSTRAP_MPC:-$SKIP_BOOTSTRAP}
SKIP_BOOTSTRAP_ISL=${SKIP_BOOTSTRAP_ISL:-$SKIP_BOOTSTRAP}

SKIP_BOOTSTRAP_BINUTILS=${SKIP_BOOTSTRAP_BINUTILS:-$SKIP_BOOTSTRAP}

SKIP_TOOLS=${SKIP_TOOLS:-false}
SKIP_LIBS=${SKIP_LIBS:-false}
SKIP_FINALIZE=${SKIP_FINALIZE:-false}
SKIP_USERS_GROUPS=${SKIP_USERS_GROUPS:-false}

SKIP_M4=${SKIP_M4:-$SKIP_TOOLS}
SKIP_AUTOCONF=${SKIP_AUTOCONF:-$SKIP_TOOLS}
SKIP_AUTOMAKE=${SKIP_AUTOMAKE:-$SKIP_TOOLS}
SKIP_LIBTOOL=${SKIP_LIBTOOL:-$SKIP_TOOLS}
SKIP_PKG_CONFIG=${SKIP_PKG_CONFIG:-$SKIP_TOOLS}
SKIP_CCACHE=${SKIP_CCACHE:-$SKIP_TOOLS}
SKIP_CMAKE=${SKIP_CMAKE:-$SKIP_TOOLS}
SKIP_PYTHON=${SKIP_PYTHON:-$SKIP_TOOLS}

SKIP_LIBSTDCXX=${SKIP_LIBSTDCXX:-$SKIP_LIBS}
SKIP_ZLIB=${SKIP_ZLIB:-$SKIP_LIBS}
SKIP_OPENSSL=${SKIP_OPENSSL:-$SKIP_LIBS}
SKIP_CURL=${SKIP_CURL:-$SKIP_LIBS}
SKIP_SQLITE=${SKIP_SQLITE:-$SKIP_LIBS}

# -----------------------------------------------------------------------------

function download_and_extract()
{
  local ARCHIVE_NAME="$1"
  local URL="$2"
  local regex='\.bz2$'

  if [[ ! -f "${XBB_DOWNLOAD}/${ARCHIVE_NAME}" ]]; then
    rm -f "${XBB_DOWNLOAD}/${ARCHIVE_NAME}.tmp"
    "${XBB_BOOTSTRAP}/bin/curl" --fail -L -o "${XBB_DOWNLOAD}/${ARCHIVE_NAME}.tmp" "${URL}"
    mv "${XBB_DOWNLOAD}/${ARCHIVE_NAME}.tmp" "${XBB_DOWNLOAD}/${ARCHIVE_NAME}"
  fi
  if [[ "${URL}" =~ $regex ]]; then
    tar xjf "${XBB_DOWNLOAD}/${ARCHIVE_NAME}"
  else
    tar xzf "${XBB_DOWNLOAD}/${ARCHIVE_NAME}"
  fi
}

function extract()
{
  local ARCHIVE_NAME="$1"
  local regex='\.bz2$'

  if [[ "${ARCHIVE_NAME}" =~ $regex ]]; then
    tar xjf "${XBB_INPUT}/${ARCHIVE_NAME}"
  else
    tar xzf "${XBB_INPUT}/${ARCHIVE_NAME}"
  fi
}

function eval_bool()
{
  local VAL="$1"
  [[ "${VAL}" = 1 || "${VAL}" = true || "${VAL}" = yes || "${VAL}" = y ]]
}

# $1=path ($XBB_BOOTSTRAP)
function xbb_activate()
{
	local BB_
	if [ $# -gt 0 ]
	then
		BB_=$1
	else
		BB_=${XBB}
	fi
  export PATH=${BB_}/bin:${PATH}
	export C_INCLUDE_PATH=${BB_}/include
	export CPLUS_INCLUDE_PATH=${BB_}/include
	export LIBRARY_PATH=${BB_}/lib
	export PKG_CONFIG_PATH=${BB_}/lib/pkgconfig:/usr/lib/pkgconfig
	export CPPFLAGS=-I{$BB_}/include
	export LDPATHFLAGS="-L${BB_}/lib -Wl,-rpath,${BB_}/lib"
	export LDFLAGS="${LDPATHFLAGS}"
	export LD_LIBRARY_PATH=${BB_}/lib
}

# -----------------------------------------------------------------------------

mkdir -p "${XBB}"

mkdir -p "${XBB_TMP}"
mkdir -p "${XBB_DOWNLOAD}"
mkdir -p "${XBB_BUILD}"

mkdir -p "${XBB_BOOTSTRAP}"
mkdir -p "${XBB_BOOTSTRAP_BUILD}"

if ! eval_bool "${SKIP_BOOTSTRAP_OPENSSL}"
then
  echo "Building bootstrap OpenSSL ${XBB_OPENSSL_VERSION}..."
  cd "${XBB_BOOTSTRAP_BUILD}"

  extract "${XBB_OPENSSL_ARCHIVE}" 

  pushd "${XBB_OPENSSL_FOLDER}"
  (
    xbb_activate "${XBB_BOOTSTRAP}"

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

	extract "${XBB_CURL_ARCHIVE}" 

  pushd "${XBB_CURL_FOLDER}"
	(
    xbb_activate "${XBB_BOOTSTRAP}"

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

if ! eval_bool "${SKIP_BOOTSTRAP_M4}"
then
	echo "Building bootstrap m4 ${XBB_M4_VERSION}..."
  cd "${XBB_BOOTSTRAP_BUILD}"

	download_and_extract "${XBB_M4_ARCHIVE}" "${XBB_M4_URL}"

  pushd "${XBB_M4_FOLDER}"
	(
		xbb_activate "${XBB_BOOTSTRAP}"

		./configure --prefix="${XBB_BOOTSTRAP}" --disable-shared --enable-static
		make -j${MAKE_CONCURRENCY}
		make install-strip
	)
	if [[ "$?" != 0 ]]; then false; fi
	popd
fi

if ! eval_bool "${SKIP_BOOTSTRAP_GAWK}"
then
	echo "Building bootstrap gawk ${XBB_GAWK_VERSION}..."
  cd "${XBB_BOOTSTRAP_BUILD}"

	download_and_extract "${XBB_GAWK_ARCHIVE}" "${XBB_GAWK_URL}"

  pushd "${XBB_GAWK_FOLDER}"
	(
		xbb_activate "${XBB_BOOTSTRAP}"

		./configure --prefix="${XBB_BOOTSTRAP}" --disable-shared --enable-static
		make -j${MAKE_CONCURRENCY}
		make install-strip
	)
	if [[ "$?" != 0 ]]; then false; fi
	popd
fi

if ! eval_bool "${SKIP_BOOTSTRAP_TAR}"
then
	echo "Building bootstrap tar ${XBB_TAR_VERSION}..."
  cd "${XBB_BOOTSTRAP_BUILD}"

	download_and_extract "${XBB_TAR_ARCHIVE}" "${XBB_TAR_URL}"

  pushd "${XBB_TAR_FOLDER}"
	(
		xbb_activate "${XBB_BOOTSTRAP}"

		export FORCE_UNSAFE_CONFIGURE=1
		./configure --prefix="${XBB_BOOTSTRAP}" --disable-shared --enable-static
		make -j${MAKE_CONCURRENCY}
		make install-strip
	)
	if [[ "$?" != 0 ]]; then false; fi
	popd
fi

if ! eval_bool "${SKIP_BOOTSTRAP_AUTOCONF}"; then
	echo "Building bootstrap autoconf ${XBB_AUTOCONF_VERSION}..."
  cd "${XBB_BOOTSTRAP_BUILD}"

	download_and_extract "${XBB_AUTOCONF_ARCHIVE}" "${XBB_AUTOCONF_URL}"

  pushd "${XBB_AUTOCONF_FOLDER}"
	(
		xbb_activate "${XBB_BOOTSTRAP}"

		./configure --prefix="${XBB_BOOTSTRAP}" --disable-shared --enable-static
		make -j${MAKE_CONCURRENCY}
		make install-strip
	)
	if [[ "$?" != 0 ]]; then false; fi
	popd
fi

if ! eval_bool "${SKIP_BOOTSTRAP_AUTOMAKE}"; then
	echo "Building bootstrap automake ${XBB_AUTOMAKE_VERSION}..."
  cd "${XBB_BOOTSTRAP_BUILD}"

	download_and_extract "${XBB_AUTOMAKE_ARCHIVE}" "${XBB_AUTOMAKE_URL}"

  pushd "${XBB_AUTOMAKE_FOLDER}"
	(
		xbb_activate "${XBB_BOOTSTRAP}"

		./configure --prefix="${XBB_BOOTSTRAP}" --disable-shared --enable-static
		make -j${MAKE_CONCURRENCY}
		make install-strip
	)
	if [[ "$?" != 0 ]]; then false; fi
	popd
fi

if ! eval_bool "${SKIP_BOOTSTRAP_LIBTOOL}"; then
	echo "Building bootstrap libtool ${XBB_LIBTOOL_VERSION}..."
  cd "${XBB_BOOTSTRAP_BUILD}"

	download_and_extract "${XBB_LIBTOOL_ARCHIVE}" "${XBB_LIBTOOL_URL}"

  pushd "${XBB_LIBTOOL_FOLDER}"
	(
		xbb_activate "${XBB_BOOTSTRAP}"

		./configure --prefix="${XBB_BOOTSTRAP}" --disable-shared --enable-static
		make -j${MAKE_CONCURRENCY}
		make install-strip
	)
	if [[ "$?" != 0 ]]; then false; fi
	popd
fi

if ! eval_bool "${SKIP_BOOTSTRAP_PKG_CONFIG}"; then
	echo "Building bootstrap pkg-config ${XBB_PKG_CONFIG_VERSION}..."
  cd "${XBB_BOOTSTRAP_BUILD}"

	download_and_extract "${XBB_PKG_CONFIG_ARCHIVE}" "${XBB_PKG_CONFIG_URL}"

  pushd "${XBB_PKG_CONFIG_FOLDER}"
	(
		xbb_activate "${XBB_BOOTSTRAP}"

		./configure --prefix="${XBB_BOOTSTRAP}" --with-internal-glib
		rm -f "${XBB_BOOTSTRAP}/bin"/*pkg-config
		make -j${MAKE_CONCURRENCY} install-strip
	)
	if [[ "$?" != 0 ]]; then false; fi
	popd
fi

if ! eval_bool "${SKIP_BOOTSTRAP_GMP}"; then
	echo "Building bootstrap gmp ${XBB_GMP_VERSION}..."
  cd "${XBB_BOOTSTRAP_BUILD}"

	download_and_extract "${XBB_GMP_ARCHIVE}" "${XBB_GMP_URL}"

  pushd "${XBB_GMP_FOLDER}"
	(
		xbb_activate "${XBB_BOOTSTRAP}"

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
		xbb_activate "${XBB_BOOTSTRAP}"

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
		xbb_activate "${XBB_BOOTSTRAP}"

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
		xbb_activate "${XBB_BOOTSTRAP}"

		./configure --prefix="${XBB_BOOTSTRAP}" --disable-shared --enable-static
		make -j${MAKE_CONCURRENCY}
		make install-strip
	)
	if [[ "$?" != 0 ]]; then false; fi
	popd
fi


# -----------------------------------------------------------------------------



if ! eval_bool "$SKIP_CMAKE"; then
	echo "Installing CMake $XBB_CMAKE_VERSION"
  cd "$XBB_TMP"

	download_and_extract cmake-$XBB_CMAKE_VERSION.tar.gz \
		https://cmake.org/files/v$XBB_CMAKE_MAJOR_VERSION/cmake-$XBB_CMAKE_VERSION.tar.gz

	pushd cmake-$XBB_CMAKE_VERSION
	(
		xbb_activate

		./configure --prefix=$XBB --no-qt-gui --parallel=$MAKE_CONCURRENCY
		make -j$MAKE_CONCURRENCY
		make install
		strip --strip-all $XBB/bin/cmake
	)
	if [[ "$?" != 0 ]]; then false; fi
	popd
fi

if ! eval_bool "$SKIP_PYTHON"; then
	echo "Installing Python $XBB_PYTHON_VERSION"
  cd "$XBB_TMP"

	download_and_extract Python-$XBB_PYTHON_VERSION.tgz \
		https://www.python.org/ftp/python/$XBB_PYTHON_VERSION/Python-$XBB_PYTHON_VERSION.tgz

  pushd Python-$XBB_PYTHON_VERSION
	(
		xbb_activate

		./configure --prefix=$XBB
		make -j$MAKE_CONCURRENCY install
		strip --strip-all $XBB/bin/python
		strip --strip-debug $XBB/lib/python*/lib-dynload/*.so
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

# rm -rf "$XBB_DOWNLOAD"
# rm -rf "$XBB_BOOTSTRAP" "$XBB_BOOTSTRAP_BUILD"
# rm "$XBB_BUILD"
# rm -rf "$XBB_TMP"
# rm -rf "$XBB_INPUT"