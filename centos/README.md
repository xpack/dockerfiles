## Docker files to create CentOS images

The idea is to layer several images, from simple to complex, aiming to an image with a set of modern tools, but based on a very conservative set of system libraries, that can be used to build applications that have a good chance to run on as many GNU/Linux distributions, new or old.

To test the images, use something like:

```console
$ docker run --interactive --tty ilegeul/centos:5-bootstrap
```

### 5-final

This creates a Docker image with the latest version of a CentOS 5 system.

CentOS 5 reached end of life, and the latest packages (v5.11) were archived in the [vault](http://vault.centos.org/5.11/).

The docker script patches the system to use the vault, then updates everything to the latest available versions.


### 5-develop

On top of the final CentOS 5.11, this script adds some of the development tools, required to build the bootstrap and the newer compiler.

The compiler is GCC 4.1.2, too old for modern builds.

Another limitation is `curl`, which cannot access https sites.

### 5-bootstrap

On top of the CentOS 5.11 development image, a set of tools are compiled from relatively new source code versions.

Some of the latest versions no longer build with GCC 4.1.2, so they required backing up a few steps, but this should not be a problem.

These tools should be enough to build a modern GCC.
