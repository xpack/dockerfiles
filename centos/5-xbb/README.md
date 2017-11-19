## 5-xbb

### Overview

Dockerfile to create a Docker image based on the latest CentOS 5 64-bits development image, plus selected new tools.

### Changes

Using the bootstrap development tools, build final newer versions of the tools from sources. 

This step installs the newly created tools in `/opt/xbb`, using several temporary folders.

To use the bootstrap tools, add `/opt/xpp-bootstrap/bin` to the path:

```console
$ source /opt/xbb/xbb.sh
$ xbb_activate
```

### Developer

To create the Docker image locally, use:

```console
$ cd ...
$ docker build --tag "ilegeul/centos:5-xbb" -f Dockerfile .
```

On macOS, to prevent entering sleep, use:

```console
$ caffeinate docker build --tag "ilegeul/centos:5-xbb" -f Dockerfile .
```

To test the image:

```console
$ docker run --interactive --tty ilegeul/centos:5-xbb
```

To create a second version:

```console
$ caffeinate docker build --tag "ilegeul/centos:5-xbb-v2" -f Dockerfile-v2 .
```

To publish, use:

```console
$ docker push "ilegeul/centos:5-xbb"
```

### Failure!

The 'old glibc with new gcc' bug (https://github.com/jedisct1/libsodium/issues/202) apparently affects the GCC build too:

```console
.libs/jmpbuf.o: In function `__cilkrts_get_sp':
/tmp/xbb/xbb-build/gcc-7.2.0-build/x86_64-pc-linux-gnu/libcilkrts/../../../gcc-7.2.0/libcilkrts/runtime/jmpbuf.h:135: multiple definition of `__cilkrts_get_sp'
.libs/full_frame.o:/tmp/xbb/xbb-build/gcc-7.2.0-build/x86_64-pc-linux-gnu/libcilkrts/../../../gcc-7.2.0/libcilkrts/runtime/jmpbuf.h:135: first defined here
.libs/jmpbuf.o: In function `__cilkrts_get_frame_size':
/tmp/xbb/xbb-build/gcc-7.2.0-build/x86_64-pc-linux-gnu/libcilkrts/../../../gcc-7.2.0/libcilkrts/runtime/jmpbuf.h:154: multiple definition of `__cilkrts_get_frame_size'
.libs/full_frame.o:/tmp/xbb/xbb-build/gcc-7.2.0-build/x86_64-pc-linux-gnu/libcilkrts/../../../gcc-7.2.0/libcilkrts/runtime/jmpbuf.h:154: first defined here
.libs/pedigrees.o: In function `update_pedigree_on_leave_frame':
/tmp/xbb/xbb-build/gcc-7.2.0-build/x86_64-pc-linux-gnu/libcilkrts/../../../gcc-7.2.0/libcilkrts/runtime/pedigrees.h:130: multiple definition of `update_pedigree_on_leave_frame'
.libs/cilk-abi.o:/tmp/xbb/xbb-build/gcc-7.2.0-build/x86_64-pc-linux-gnu/libcilkrts/../../../gcc-7.2.0/libcilkrts/runtime/pedigrees.h:130: first defined here
.libs/scheduler.o: In function `update_pedigree_on_leave_frame':
/tmp/xbb/xbb-build/gcc-7.2.0-build/x86_64-pc-linux-gnu/libcilkrts/../../../gcc-7.2.0/libcilkrts/runtime/pedigrees.h:130: multiple definition of `update_pedigree_on_leave_frame'
.libs/cilk-abi.o:/tmp/xbb/xbb-build/gcc-7.2.0-build/x86_64-pc-linux-gnu/libcilkrts/../../../gcc-7.2.0/libcilkrts/runtime/pedigrees.h:130: first defined here
.libs/sysdep-unix.o: In function `__cilkrts_get_sp':
/tmp/xbb/xbb-build/gcc-7.2.0-build/x86_64-pc-linux-gnu/libcilkrts/../../../gcc-7.2.0/libcilkrts/runtime/jmpbuf.h:135: multiple definition of `__cilkrts_get_sp'
.libs/full_frame.o:/tmp/xbb/xbb-build/gcc-7.2.0-build/x86_64-pc-linux-gnu/libcilkrts/../../../gcc-7.2.0/libcilkrts/runtime/jmpbuf.h:135: first defined here
.libs/sysdep-unix.o: In function `__cilkrts_get_frame_size':
/tmp/xbb/xbb-build/gcc-7.2.0-build/x86_64-pc-linux-gnu/libcilkrts/../../../gcc-7.2.0/libcilkrts/runtime/jmpbuf.h:154: multiple definition of `__cilkrts_get_frame_size'
.libs/full_frame.o:/tmp/xbb/xbb-build/gcc-7.2.0-build/x86_64-pc-linux-gnu/libcilkrts/../../../gcc-7.2.0/libcilkrts/runtime/jmpbuf.h:154: first defined here
collect2: error: ld returned 1 exit status
make[2]: *** [libcilkrts.la] Error 1
make[2]: Leaving directory `/tmp/xbb/xbb-build/gcc-7.2.0-build/x86_64-pc-linux-gnu/libcilkrts'
make[1]: *** [all-target-libcilkrts] Error 2
```