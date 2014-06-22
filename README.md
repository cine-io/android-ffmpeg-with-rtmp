# android-ffmpeg-with-rtmp

This repository contains script(s) to build ffmpeg for android with RTMP (and OpenSSL) support.

## Status

This should successfully build ffmpeg for android. I haven't done much testing yet, however.

**YOU'VE BEEN WARNED.**

## Instructions

1. Install the [Android NDK][android-ndk].
2. Ensure that [cURL][cURL] is installed.
3. Clone this repository.
4. Run `build-ffmpeg.sh`.

For example:

```bash
$ git clone git@github.com:cine-io/android-ffmpeg-with-rtmp.git
$ cd android-ffmpeg-with-rtmp
$ ./build-ffmpeg.sh
```

## Notes

The first time you run the script, it will try to find the location where
you've installed the NDK. It will also try to auto-detect your operating
system and architecture. This process might take a minute or two, so the
information will be saved into a configuration file called `.build-ffmpeg-
config.sh` which will be used on subsequent executions of the script.

The script is meant to be idempotent. However, should you want to start over
from scratch, it's a simple matter of:

```bash
$ \rm -rf src build .build-ffmpeg-config.sh
$ ./build-ffmpeg.sh
```

## Acknowledgements

Inspired by: [openssl-android][openssl-android] and [FFmpeg-Android][FFmpeg-Android].


<!-- external links -->
[openssl-android]:https://github.com/guardianproject/openssl-android
[FFmpeg-Android]:https://github.com/OnlyInAmerica/FFmpeg-Android
[android-ndk]:https://developer.android.com/tools/sdk/ndk/index.html
[cURL]:http://curl.haxx.se/