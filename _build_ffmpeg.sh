function build_ffmpeg {
  echo "Building ffmpeg for android ..."

  # download ffmpeg
  ffmpeg_archive=${src_root}/ffmpeg-snapshot.tar.bz2
  if [ ! -f "${ffmpeg_archive}" ]; then
    test -x "$(which curl)" || die "You must install curl!"
    curl -s http://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2 -o ${ffmpeg_archive} >> ${build_log} 2>&1 || \
      die "Couldn't download ffmpeg sources!"
  fi

  # extract ffmpeg
  if [ ! -d "${src_root}/ffmpeg" ]; then
    cd ${src_root}
    tar xvfj ${ffmpeg_archive} >> ${build_log} 2>&1 || die "Couldn't extract ffmpeg sources!"
  fi

  cd ${src_root}/ffmpeg

  # patch the configure script to use an Android-friendly versioning scheme
  patch -u configure ${patch_root}/ffmpeg-configure.patch >> ${build_log} 2>&1 || \
    die "Couldn't patch ffmpeg configure script!"

  # run the configure script
  prefix=${src_root}/ffmpeg/android/arm
  addi_cflags="-marm"
  addi_ldflags=""
  export PKG_CONFIG_PATH="${src_root}/openssl-android:${src_root}/rtmpdump/librtmp"
  ./configure \
    --prefix=${prefix} \
    --enable-shared \
    --disable-static \
    --disable-doc \
    --disable-ffplay \
    --disable-ffprobe \
    --disable-ffserver \
    --disable-symver \
    --cross-prefix=${TOOLCHAIN}/bin/arm-linux-androideabi- \
    --target-os=linux \
    --arch=arm \
    --enable-cross-compile \
    --enable-librtmp \
    --sysroot=${SYSROOT} \
    --extra-cflags="-Os -fpic ${addi_cflags}" \
    --extra-ldflags="-L${src_root}/openssl-android/libs/armeabi ${addi_ldflags}" \
    --pkg-config=$(which pkg-config) >> ${build_log} 2>&1 || die "Couldn't configure ffmpeg!"

  # build
  make >> ${build_log} 2>&1 || die "Couldn't build ffmpeg!"
  make install >> ${build_log} 2>&1 || die "Couldn't install ffmpeg!"

  # copy the versioned libraries
  cp ${prefix}/lib/lib*-+([0-9]).so ${dist_lib_root}/.
  # copy the executables
   cp ${prefix}/bin/ff* ${dist_bin_root}/.
  # copy the headers
  cp -r ${prefix}/include/* ${dist_include_root}/.

  cd ${top_root}
}
