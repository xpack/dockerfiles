
## nsis

Attempts failed with:

```console
Checking for C library z... yes
Checking for C library zdll... no
Checking for C library z... no
zlib (win32) is missing!
```

```bash
# http://nsis.sourceforge.net/
# https://sourceforge.net/projects/nsis/files/NSIS%203/3.02.1/
# 2017-08-01
XBB_NSIS_MAJOR_VERSION="3.02"
XBB_NSIS_VERSION="${XBB_NSIS_MAJOR_VERSION}.1"
XBB_NSIS_FOLDER="nsis-${XBB_NSIS_VERSION}-src"
XBB_NSIS_ARCHIVE="${XBB_NSIS_FOLDER}.tar.bz2"
XBB_NSIS_URL="https://sourceforge.net/projects/nsis/files/NSIS%203/${XBB_NSIS_VERSION}/${XBB_NSIS_ARCHIVE}"

# -----

if ! eval_bool "${SKIP_NSIS}"
then
  echo
  echo "Installing nsis ${XBB_NSIS_VERSION}"
  cd "${XBB_BUILD}"

  download_and_extract "${XBB_NSIS_ARCHIVE}" "${XBB_NSIS_URL}"

  curl --fail -L -o zlib123-dll.zip https://downloads.sourceforge.net/project/libpng/zlib/1.2.3/zlib123-dll.zip
  mkdir -p "${XBB_NSIS_FOLDER}-zlib"
  
  (cd "${XBB_NSIS_FOLDER}-zlib"; unzip ../zlib123-dll.zip)
  ls -lLR "${XBB_BUILD}/${XBB_NSIS_FOLDER}-zlib"

  pushd "${XBB_NSIS_FOLDER}"
  (
    export PATH="${XBB}/bin":${PATH}

    # Don't strip, there were some odd errors reported.
    scons \
      PREFIX="${XBB}" \
      PREFIX_CONF="${XBB}/etc" \
      ZLIB_W32="${XBB_BUILD}/${XBB_NSIS_FOLDER}-zlib" \
      VERSION="${XBB_NSIS_MAJOR_VERSION}" \
      SKIPUTILS='NSIS Menu' \
      NSIS_MAX_STRLEN=8192 \
      STRIP_CP=false \
      install

    # strip --strip-all "${XBB}/bin"/git "${XBB}/bin"/git-[rsu]*
  )
  if [[ "$?" != 0 ]]; then false; fi
  popd

  hash -r
fi
```

Inspiration:
- https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=nsis