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

# Script to add TeX to a CentOS Docker image.
#
# The TeX files are installed in 
#
# /opt/texlive
# 
# To use the binaries, add one of the following to the PATH:
#
# /opt/texlive/x86_64-linux
# /opt/texlive/i686-linux
#

# -----------------------------------------------------------------------------

XBB_INPUT="/xbb-input"
XBB_DOWNLOAD="/tmp/xbb-download"

MAKE_CONCURRENCY=2

# -----------------------------------------------------------------------------

mkdir -p "${XBB_DOWNLOAD}"

# -----------------------------------------------------------------------------

# x86_64 or i686
UNAME_ARCH=$(uname -p)
if [ "${UNAME_ARCH}" == "x86_64" ]
then
  BITS="64"
  LIB_ARCH="lib64"
elif [ "${UNAME_ARCH}" == "i686" ]
then
  BITS="32"
  LIB_ARCH="lib"
fi

build=${UNAME_ARCH}-linux-gnu

# -----------------------------------------------------------------------------

# Make all tools choose gcc, not the old cc.
export CC=gcc
export CXX=g++

# -----------------------------------------------------------------------------


# =============================================================================

function do_texlive() 
{

  echo
  echo "Installing texlive..."

  # https://www.tug.org/texlive/acquire-netinstall.html

  # The master is
  # ftp://tug.org/historic, and it is mirrored at
  # ftp://ftp.math.utah.edu/pub/tex/historic and
  # http://www.math.utah.edu/pub/tex/historic.

  # XBB_TEXLIVE_HISTORIC_URL="ftp://tug.org/historic"
  XBB_TEXLIVE_HISTORIC_URL="http://ftp.math.utah.edu/pub/tex/historic"
  XBB_TEXLIVE_FOLDER="install-tl"
  XBB_TEXLIVE_ARCHIVE="install-tl-unx.tar.gz"
  XBB_TEXLIVE_EDITION="2016"
  XBB_TEXLIVE_URL="${XBB_TEXLIVE_HISTORIC_URL}/systems/texlive/${XBB_TEXLIVE_EDITION}/${XBB_TEXLIVE_ARCHIVE}"
  XBB_TEXLIVE_REPO_URL="${XBB_TEXLIVE_HISTORIC_URL}/systems/texlive/${XBB_TEXLIVE_EDITION}/tlnet-final"
  XBB_TEXLIVE_PREFIX="/opt/texlive"

  wget -O "${XBB_DOWNLOAD}/${XBB_TEXLIVE_ARCHIVE}" "${XBB_TEXLIVE_URL}"

# Create the texlive.profile used to automate the install.
# These definitions are specific to TeX Live 2016.
tmp_profile=$(mktemp)

# Note: __EOF__ is not quoted to allow local substitutions.
cat <<__EOF__ > "${tmp_profile}"
# texlive.profile
TEXDIR ${XBB_TEXLIVE_PREFIX}
TEXMFCONFIG ~/.texlive/texmf-config
TEXMFHOME ~/texmf
TEXMFLOCAL ${XBB_TEXLIVE_PREFIX}/texmf-local
TEXMFSYSCONFIG ${XBB_TEXLIVE_PREFIX}/texmf-config
TEXMFSYSVAR ${XBB_TEXLIVE_PREFIX}/texmf-var
TEXMFVAR ~/.texlive/texmf-var

option_doc 0
option_src 0
__EOF__

  (
    mkdir -p "${XBB_TEXLIVE_FOLDER}"
    cd "${XBB_TEXLIVE_FOLDER}"

    tar x -v --strip-components 1 -f "${XBB_DOWNLOAD}/${XBB_TEXLIVE_ARCHIVE}"

    ls -lL

    mkdir -p "${XBB_TEXLIVE_PREFIX}"

    export PATH="${XBB_TEXLIVE_PREFIX}"/bin/"${UNAME_ARCH}"-linux:${PATH}

    set +e

    "./install-tl" \
      -repository "${XBB_TEXLIVE_REPO_URL}" \
      -no-gui \
      -lang en \
      -profile "${tmp_profile}" \
      -scheme full

    # Keep no backups (not required, simply makes cache bigger)
    tlmgr option -- autobackup 0

    set -e

    # The following errors were encountered:
    # fmtutil [INFO]: /opt/texlive/texmf-var/web2c/pdftex/cslatex.fmt installed.
    # fmtutil [ERROR]: running `xetex -ini   -jobname=xetex -progname=xetex -etex xetex.ini </dev/null' return status 127
    # fmtutil [ERROR]: return error due to options --strict
    # fmtutil [ERROR]: running `xetex -ini   -jobname=cont-en -progname=context -8bit *cont-en.mkii </dev/null' return status 127
    # fmtutil [ERROR]: return error due to options --strict
    # fmtutil [ERROR]: running `xetex -ini   -jobname=xelatex -progname=xelatex -etex xelatex.ini </dev/null' return status 127
    # fmtutil [ERROR]: return error due to options --strict
    # fmtutil [ERROR]: running `xetex -ini   -jobname=pdfcsplain -progname=pdfcsplain -etex csplain.ini </dev/null' return status 127
    # fmtutil [ERROR]: return error due to options --strict
    # fmtutil [INFO]: Disabled formats: 6
    # fmtutil [INFO]: Successfully rebuilt formats: 40
    # fmtutil [INFO]: Failed to build: 4 (xetex/xetex xetex/cont-en xetex/xelatex xetex/pdfcsplain)
    # fmtutil [INFO]: Total formats: 50
    # fmtutil [INFO]: exiting with status 4

    if [ -f "${XBB_TEXLIVE_PREFIX}"/install-tl.log ]
    then
      cat "${XBB_TEXLIVE_PREFIX}"/install-tl.log 1>&2
    fi
  )

  hash -r
}

# -----------------------------------------------------------------------------

function do_cleanup()
{
  rm -rf "${XBB_DOWNLOAD}"
  rm -rf "${XBB_INPUT}"
}
# =============================================================================

do_texlive

do_cleanup

 # -----------------------------------------------------------------------------
