Dockerfile to create a Docker image to be used for QEMU Windows builds.

It is based on a Debian 8 64-bit, with lots of packages, including the mingw-w64.

It also includes the packages created by [Stefan Weil](http://qemu.weilnetz.de/debian/).

To create the new image use

    docker build --tag "qemu-builds:d8-x64-mingw" \
    https://github.com/ilg-ul/docker/raw/master/builds/d8_x64_mingw/Dockerfile


