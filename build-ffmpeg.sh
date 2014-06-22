#!/bin/bash

function setup {
  set -e  # fail hard on any error

  echo "Setting up ..."
  builder_root=$PWD
  build_log=${builder_root}/build/build-ffmpeg.log
  config_file=${builder_root}/.build-ffmpeg-config.sh


  if [ ! -f "${builder_root}/.build-ffmpeg-config.sh" ]; then
    # determine OS and architecture
    OS_ARCH=$(uname -sm | tr 'A-Z' 'a-z' | sed "s/\ /\-/g")

    # find / ask for the NDK
    echo "Looking for the NDK ..."
    NDK=$(find_ndk)
    echo -n "Path to NDK [$NDK]: "
    read typed_ndk_root
    test "$typed_ndk_root" && NDK="$typed_ndk_root"

    # save our configuration
    echo "OS_ARCH=$OS_ARCH" > ${config_file}
    echo "NDK=$NDK" >> ${config_file}
    echo "SYSROOT=${NDK}/platforms/android-19/arch-arm" >> ${config_file}
    echo "TOOLCHAIN=${NDK}/toolchains/arm-linux-androideabi-4.8/prebuilt/${OS_ARCH}" >> ${config_file}
  fi
  # show the user our configuration
  cat ${config_file}
  source ${config_file}
}

function die {
  code=-1
  err="Unknown error!"
  test "$1" && err=$1
  cd ${builder_root}
  echo "$err"
  echo "Check the build log: ${build_log}"
  exit -1
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
  cd ${builder_root}
  test -d ${builder_root}/src || mkdir -p ${builder_root}/src
  test -d ${builder_root}/build || mkdir -p ${builder_root}/build/libs
}

function build_openssl {
  echo "Building openssl-android ..."
  ensure_folder_structure
  test -d ${builder_root}/src/openssl-android || \
    git clone git@github.com:eighthave/openssl-android.git ${builder_root}/src/openssl-android > ${build_log} 2>&1 || \
    die "Couldn't clone openssl-android repository!"
  cd ${builder_root}/src/openssl-android
  ${NDK}/ndk-build > ${build_log} 2>&1 || die "Couldn't build openssl-android!"
}

function build_librtmp {
  echo "Building librtmp for android ..."
  ensure_folder_structure
  test -d src/rtmpdump || \
    git clone git://git.ffmpeg.org/rtmpdump ${builder_root}/src/rtmpdump > ${build_log} 2>&1 || \
    die "Couldn't clone rtmpdump repository!"

  cd ${builder_root}/src/rtmpdump/librtmp

  openssl_dir=${builder_root}/src/openssl-android
  prefix=${builder_root}/src/rtmpdump/librtmp/android/arm
  addi_cflags="-marm"

  test -L "crtbegin_so.o" || ln -s ${SYSROOT}/usr/lib/crtbegin_so.o
  test -L "crtend_so.o" || ln -s ${SYSROOT}/usr/lib/crtend_so.o
  export XLDFLAGS="$addi_ldflags -L${openssl_dir}/libs/armeabi -L${SYSROOT}/usr/lib "
  export CROSS_COMPILE=${TOOLCHAIN}/bin/arm-linux-androideabi-
  export XCFLAGS="${addi_cflags} -I${openssl_dir}/include -isysroot ${SYSROOT}"
  export INC="-I${SYSROOT}"
  make prefix=\"${prefix}\" OPT= install > ${build_log} 2>&1 || \
    die "Couldn't build librtmp for android!"
}

function build_ffmpeg {
  echo "Building ffmpeg for android ..."
  ensure_folder_structure
}

#-- main

setup
build_openssl
build_librtmp
build_ffmpeg
