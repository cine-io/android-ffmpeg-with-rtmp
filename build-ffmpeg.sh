#!/bin/bash

function setup {
  echo "Setting up ..."
  set -e
  if [ -f "$builder_root/.build-ffmpeg-config.sh" ]; then
    source $builder_root/.build-ffmpeg-config.sh
  else
    echo "Looking for the NDK ..."
    NDK=$(find_ndk)
    echo -n "Path to NDK [$NDK]: "
    read typed_NDK
    test "$typed_ndk_root" && NDK="$typed_ndk_root"
    echo "NDK=$NDK" > .build-ffmpeg-config.sh
    echo "SYSROOT=$NDK/platforms/android-19/arch-arm" >> .build-ffmpeg-config.sh
    echo "TOOLCHAIN=$NDK/toolchains/arm-linux-androideabi-4.8/prebuilt/darwin-x86_64" >> .build-ffmpeg-config.sh
  fi
  cat .build-ffmpeg-config.sh
}

function die {
  code=-1
  err="Unknown error!"
  test "$1" && err=$1
  cd $builder_root
  echo "$err" && exit $code
}

function find_ndk {
  ndk_name="android-ndk-r9d"
  top_level_paths_to_search="/Users /Applications /usr /blah"
  found_ndk=""
  for d in $top_level_paths_to_search; do
    test -d "$d" || continue
    found_ndk=$(find $d -name $ndk_name -print)
    test "$found_ndk" && break
  done
  echo "$found_ndk"
}


function ensure_folder_structure {
  # create our src and build directory
  cd $builder_root
  test -d src || mkdir -p src
  test -d build || mkdir -p build/libs
}

function build_openssl {
  echo "Building openssl-android ..."
  ensure_folder_structure
  test -d src/openssl-android || \
    git clone git@github.com:eighthave/openssl-android.git src/openssl-android > /dev/null 2>&1 || \
    die "Couldn't clone openssl-android repository!"
  cd $builder_root/src/openssl-android
  $NDK/ndk-build > /dev/null 2>&1 || die "Couldn't build openssl-android!"
}

function build_librtmp {
  echo "Building librtmp for android ..."
  ensure_folder_structure
  test -d src/rtmpdump || \
    git clone git://git.ffmpeg.org/rtmpdump src/rtmpdump > /dev/null 2>&1 || \
    die "Couldn't clone rtmpdump repository!"

  cd $builder_root/src/rtmpdump/librtmp

  OPENSSL_DIR=$builder_root/src/openssl-android
  PREFIX=$builder_root/src/rtmpdump/librtmp/android/arm
  ADDI_CFLAGS="-marm"

  test -s "${SYSROOT}/usr/lib/crtbegin_so.o" || ln -s ${SYSROOT}/usr/lib/crtbegin_so.o
  test -s "${SYSROOT}/usr/lib/crtend_so.o" || ln -s ${SYSROOT}/usr/lib/crtend_so.o
  export XLDFLAGS="$ADDI_LDFLAGS -L${OPENSSL_DIR}/libs/armeabi -L${SYSROOT}/usr/lib "
  export CROSS_COMPILE=$TOOLCHAIN/bin/arm-linux-androideabi-
  export XCFLAGS="${ADDI_CFLAGS} -I${OPENSSL_DIR}/include -isysroot ${SYSROOT}"
  export INC="-I${SYSROOT}"
  make prefix=\"${PREFIX}\" OPT= install > /dev/null 2>&1 || \
    die "Couldn't build librtmp for android!"
}

function build_ffmpeg {
  echo "Building "
  ensure_folder_structure
}

#-- main

builder_root=$PWD
setup
build_openssl
build_librtmp
