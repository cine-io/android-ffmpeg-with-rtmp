# android-ffmpeg-with-rtmp

This repository contains script(s) to build ffmpeg for android with RTMP (and OpenSSL) support.

## Instructions

1. Install the [Android NDK][android-ndk] (tested with version r10).
2. Ensure that [cURL][cURL] is installed.
3. Ensure that [pkg-config][pkg-config] is installed.
4. Clone this repository and `cd` into its directory.
5. Run `build.sh`.
6. Look in `build/dist` for the resulting libraries and executables.
7. Look in `build/build.log` if something goes wrong.

For example:

```bash
$ git clone git@github.com:cine-io/android-ffmpeg-with-rtmp.git
$ cd android-ffmpeg-with-rtmp
$ ./build.sh
```

## Notes

The first time you run the script, it will try to find the location where
you've installed the NDK. It will also try to auto-detect your operating
system and architecture. This process might take a minute or two, so the
information will be saved into a configuration file called
`.build-config.sh` which will be used on subsequent executions of
the script.

The script is meant to be idempotent. However, should you want to start over
from scratch, it's a simple matter of:

```bash
$ rm -rf src build .build-config.sh
$ ./build.sh
```

## Android

To use `ffmpeg` with an Android app you will need to deploy the binaries along 
with the libraries.  Here's a listing of the `build/dist` directory.

```
.
├── bin
│   ├── ffmpeg
│   ├── openssl
│   └── ssltest
└── lib
    ├── libavcodec-56.so
    ├── libavdevice-56.so
    ├── libavfilter-5.so
    ├── libavformat-56.so
    ├── libavutil-54.so
    ├── libcrypto.so
    ├── librtmp-1.so
    ├── libssl.so
    ├── libswresample-1.so
    └── libswscale-3.so
```

A simple way to deploy the binaries would be to archive (e.g. zip) these directories
and copy the archive in a res/raw directory within the Android project.  Then at runtime, 
unpack the archive into a directory accessible to the app and set the appropriate permissions, 
e.g. chmod 750 -R directory-name.

In order for the Android app to use the libraries the LD_LIBRARY_PATH must be set to the location
where the libraries reside.  For example:

```java
// Change the permissions
Runtime.getRuntime().exec("chmod -R 0750 "+ abspath).waitFor();
	
//...
    
ProcessBuilder processBuilder = new ProcessBuilder(cmd);

final Map<String, String> environment = processBuilder.environment();

environment.put("LD_LIBRARY_PATH", context.getDir("lib", 0).getAbsolutePath());

Process process = processBuilder.start();

//...
```


## Acknowledgements

Inspired by: [openssl-android][openssl-android] and [FFmpeg-Android][FFmpeg-Android].


<!-- external links -->
[openssl-android]:https://github.com/guardianproject/openssl-android
[FFmpeg-Android]:https://github.com/OnlyInAmerica/FFmpeg-Android
[android-ndk]:https://developer.android.com/tools/sdk/ndk/index.html
[cURL]:http://curl.haxx.se/
[pkg-config]:http://www.freedesktop.org/wiki/Software/pkg-config/
