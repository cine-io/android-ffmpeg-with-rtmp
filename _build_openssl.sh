function build_openssl {
  echo "Building openssl-android ..."

  test -d ${src_root}/openssl-android || \
    git clone git@github.com:eighthave/openssl-android.git ${src_root}/openssl-android >> ${build_log} 2>&1 || \
    die "Couldn't clone openssl-android repository!"
  cd ${src_root}/openssl-android
  ${NDK}/ndk-build >> ${build_log} 2>&1 || die "Couldn't build openssl-android!"

  # copy the versioned libraries
  cp ${src_root}/openssl-android/libs/armeabi/lib*.so ${dist_lib_root}/.
  # copy the executables
  cp ${src_root}/openssl-android/libs/armeabi/openssl ${dist_bin_root}/.
  cp ${src_root}/openssl-android/libs/armeabi/ssltest ${dist_bin_root}/.
  # copy the headers
  cp -r ${src_root}/openssl-android/include/* ${dist_include_root}/.

  cd ${top_root}
}
