function build_openssl {
  echo "Building openssl-android ..."

  test -d ${src_root}/openssl-android || \
    git clone git@github.com:eighthave/openssl-android.git ${src_root}/openssl-android >> ${build_log} 2>&1 || \
    die "Couldn't clone openssl-android repository!"
  cd ${src_root}/openssl-android
  ${NDK}/ndk-build >> ${build_log} 2>&1 || die "Couldn't build openssl-android!"

  # copy the versioned libraries and executables
  cp ${src_root}/openssl-android/libs/armeabi/* ${dist_root}/.

  cd ${top_root}
}
