#!/bin/bash -O extglob

# import our build functions
source _build_openssl.sh
source _build_librtmp.sh
source _build_ffmpeg.sh

#-- error function
function die {
  code=-1
  err="Unknown error!"
  test "$1" && err=$1
  cd ${top_root}
  echo "$err"
  echo "Check the build log: ${build_log}"
  exit -1
}


#-- try to intelligently determine where the Android NDK is installed
function find_ndk {
  ndk_name="android-ndk-r9d"
  top_level_paths_to_search="/Users /Applications /usr"
  found_ndk=""
  for d in $top_level_paths_to_search; do
    test -d "$d" || continue
    found_ndk=$(find $d -name $ndk_name -print)
    test "$found_ndk" && break
  done
  echo "$found_ndk"
}


#-- set up environment variables, folder structure, and log files
function initialize {
  echo "Setting up build environment ..."

  # environment variables
  top_root=$PWD
  src_root=${top_root}/src
  build_root=${top_root}/build
  patch_root=${top_root}/patches
  dist_root=${top_root}/build/dist
  build_log=${top_root}/build/build.log
  config_file=${top_root}/.build-config.sh

  # create our folder structure
  cd ${top_root}
  test -d ${src_root} || mkdir -p ${src_root}
  test -d ${build_root} || mkdir -p ${build_root}
  test -d ${dist_root} || mkdir -p ${dist_root}
  touch ${build_log}

  rm -f ${build_log}

  # create our configuration file if it doesn't yet exist
  if [ ! -f "${config_file}" ]; then
    # determine OS and architecture
    OS_ARCH=$(uname -sm | tr 'A-Z' 'a-z' | sed "s/\ /\-/g")

    # find / ask for the NDK
    echo "Looking for the NDK ..."
    NDK=$(find_ndk)
    echo -n "Path to NDK [$NDK]: "
    read typed_ndk_root
    test "$typed_ndk_root" && NDK="$typed_ndk_root"

    # save our configuration
    echo "Saving configuration into ${config_file} ..."
    echo "OS_ARCH=$OS_ARCH" > ${config_file}
    echo "NDK=$NDK" >> ${config_file}
    echo "SYSROOT=${NDK}/platforms/android-19/arch-arm" >> ${config_file}
    echo "TOOLCHAIN=${NDK}/toolchains/arm-linux-androideabi-4.8/prebuilt/${OS_ARCH}" >> ${config_file}
  fi

  # show the user our configuration, then import it
  cat ${config_file}
  source ${config_file}
}


#-- main
set -e  # fail hard on any error

initialize
build_openssl
build_librtmp
build_ffmpeg

echo "Look in ${dist_root} for libraries and executables."
