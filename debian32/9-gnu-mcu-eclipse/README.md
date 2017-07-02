Dockerfile to create a Docker image based on Debian 9 32-bits, 
to be used for GNU MCU Eclipse builds.

The content should generally match the content of the 64-bits image (https://github.com/ilg-ul/docker/raw/master/debian/9-gnu-mcu-eclipse/Dockerfile).

To create the Docker image, use:

```bash
$ docker build --tag "ilegeul/debian32:9-gnu-mcu-eclipse" \
https://github.com/ilg-ul/docker/raw/master/debian32/9-gnu-mcu-eclipse/Dockerfile
```

To create the Docker image locally, use:

```bash
$ cd ...
$ docker build --tag "ilegeul/debian32:9-gnu-mcu-eclipse" .
```

On macOS, to prevent entering sleep, use:

```bash
$ caffeinate bash
$ docker build --tag "ilegeul/debian32:9-gnu-mcu-eclipse" .
```

The result is something like:

```bash
$ docker images
REPOSITORY          TAG                   IMAGE ID            CREATED              SIZE
ilegeul/debian32    9-gnu-mcu-eclipse     a22ccdf38f1f        About a minute ago   3.2GB
ilegeul/debian32    9                     7348339e67f5        29 minutes ago       116MB
```

To push the Docker image to the server, use:

```bash
$ docker push "ilegeul/debian32:9-gnu-mcu-eclipse"
```
