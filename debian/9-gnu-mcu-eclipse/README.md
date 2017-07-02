Dockerfile to create a Docker image based on Debian 9 64-bits, to be used for GNU MCU Eclipse builds.

To create the Docker image, use:

```
$ docker build --tag "ilegeul/debian:9-gnu-mcu-eclipse" \
https://github.com/ilg-ul/docker/raw/master/debian/9-gnu-mcu-eclipse/Dockerfile
```

To create the Docker image locally, use:

```
$ cd ...
$ docker build --tag "ilegeul/debian:9-gnu-mcu-eclipse" .
```

On macOS, to prevent entering sleep, use:

```
$ caffeinate bash
$ docker build --tag "ilegeul/debian:9-gnu-mcu-eclipse" .
```

The result is something like:

```bash
$ docker images
REPOSITORY          TAG                   IMAGE ID            CREATED             SIZE
ilegeul/debian      9-gnu-mcu-eclipse     ff8a853cf6cb        50 seconds ago      3.2GB
debian              9                     a2ff708b7413        11 days ago         100MB
```

To push the Docker image to the server, use:

```
$ docker push "ilegeul/debian:9-gnu-mcu-eclipse"
```
