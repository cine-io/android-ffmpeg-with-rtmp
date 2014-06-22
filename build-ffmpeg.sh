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
  cd ${builder_root}
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
  cd ${builder_root}
}

function build_ffmpeg {
  echo "Building ffmpeg for android ..."
  ensure_folder_structure

  # download ffmpeg
  ffmpeg_archive=${builder_root}/src/ffmpeg-snapshot.tar.bz2
  if [ ! -f "${ffmpeg_archive}" ]; then
    echo "DOWNLOADING"
    test -x "$(which curl)" || die "You must install curl!"
    curl -s http://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2 -o ${ffmpeg_archive} > ${build_log} 2>&1 || \
      die "Couldn't download ffmpeg sources!"
  fi

  # extract ffmpeg
  if [ ! -d "${builder_root}/src/ffmpeg" ]; then
    cd ${builder_root}/src
    tar xvfj ${ffmpeg_archive} > ${build_log} 2>&1 || die "Couldn't extract ffmpeg sources!"
  fi

  # create a patch for ffmpeg's configure script using the patch template
  # rm ${builder_root}/ffmpeg-configure.patch
  # touch ${builder_root}/ffmpeg-configure.patch
  # cat ${builder_root}/ffmpeg-configure.patch-template |  \
  #   while read line ; do
  #     echo $(eval echo \"$line\") >> ${builder_root}/ffmpeg-configure.patch
  #   done

  # run the configure script
  cd ${builder_root}/src/ffmpeg
  prefix=${builder_root}/src/ffmpeg/android/arm
  addi_cflags="-marm"
  export PKG_CONFIG_PATH="${builder_root}/src/openssl-android:${builder_root}/src/rtmpdump/librtmp"
  ./configure \
    --prefix=${prefix} \
    --enable-shared \
    --disable-static \
    --disable-doc \
    --disable-symver \
    --cross-prefix=${TOOLCHAIN}/bin/arm-linux-androideabi- \
    --target-os=linux \
    --arch=arm \
    --enable-cross-compile \
    --enable-librtmp \
    --sysroot=${SYSROOT} \
    --extra-cflags="-Os -fpic ${addi_cflags}" \
    --extra-ldflags="-L${builder_root}/src/openssl-android/libs/armeabi" \
    --pkg-config=$(which pkg-config) > ${build_log} 2>&1 || die "Couldn't configure ffmpeg!"

  # build
  make
  make install

  cd ${builder_root}
}

#-- main

setup
build_openssl
build_librtmp
build_ffmpeg
