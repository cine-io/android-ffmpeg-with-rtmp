function build_librtmp {
  echo "Building librtmp for android ..."

  test -d ${src_root}/rtmpdump || \
    git clone git://git.ffmpeg.org/rtmpdump ${src_root}/rtmpdump >> ${build_log} 2>&1 || \
    die "Couldn't clone rtmpdump repository!"

  cd ${src_root}/rtmpdump/librtmp

  # patch the Makefile to use an Android-friendly versioning scheme
  patch -u Makefile ${patch_root}/librtmp-Makefile.patch >> ${build_log} 2>&1 || \
    die "Couldn't patch librtmp Makefile!"

  openssl_dir=${src_root}/openssl-android
  prefix=${src_root}/rtmpdump/librtmp/android/arm
  addi_cflags="-marm"
  addi_ldflags=""

  test -L "crtbegin_so.o" || ln -s ${SYSROOT}/usr/lib/crtbegin_so.o
  test -L "crtend_so.o" || ln -s ${SYSROOT}/usr/lib/crtend_so.o
  export XLDFLAGS="$addi_ldflags -L${openssl_dir}/libs/armeabi -L${SYSROOT}/usr/lib"
  export CROSS_COMPILE=${TOOLCHAIN}/bin/arm-linux-androideabi-
  export XCFLAGS="${addi_cflags} -I${openssl_dir}/include -isysroot ${SYSROOT}"
  export INC="-I${SYSROOT}"
  make prefix=\"${prefix}\" OPT= install >> ${build_log} 2>&1 || \
    die "Couldn't build librtmp for android!"

  # copy the versioned libraries
  cp ${src_root}/rtmpdump/librtmp/android/arm/lib/lib*-+([0-9]).so ${dist_root}/.

  cd ${top_root}
}
