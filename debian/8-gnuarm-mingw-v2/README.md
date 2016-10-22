Dockerfile to create a Docker image to be used for Windows builds.

It is based on a Debian 8 64-bits (actually the GNU ARM GCC image), plus lots of mingw-w64 packages.

To create the Docker image, use:

```
$ docker build --tag "ilegeul/debian:8-gnuarm-mingw-v2" \
https://github.com/ilg-ul/docker/raw/master/debian/8-gnuarm-mingw-v2/Dockerfile
```

To create the Docker image locally, use:

```
$ cd ...
$ docker build --tag "ilegeul/debian:8-gnuarm-mingw-v2" .
```

On macOS, to prevent entering sleep, use:

```
$ caffeinate docker build --tag "ilegeul/debian:8-gnuarm-mingw-v2" .
```

To publish, use:

```
$ docker push "ilegeul/debian:8-gnuarm-mingw-v2"
```

