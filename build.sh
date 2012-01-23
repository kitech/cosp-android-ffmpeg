#!/bin/sh

cd `dirname $0` || exit 1

. ./cosp-android-common.sh || exit 1

export PREFIX ARCH

OUTDIR=$OUTDIR/ffmpeg

CWD=`pwd`
mkdir -p $OUTDIR || exit 1
cd $OUTDIR || exit 1

CFLAGS="-O3 -fno-short-enums -fno-strict-aliasing"
CFLAGS="$CFLAGS -Wno-psabi -Wno-deprecated-declarations -Wno-unused-variable"

LDFLAGS=""

CONFIGURE_ARGS=""
case $ABI in
  armeabi)
    CONFIGURE_ARGS="$CONFIGURE_ARGS --enable-armv5te"
    ;;
  armeabi-v7a)
    CONFIGURE_ARGS="$CONFIGURE_ARGS --enable-armv5te --enable-armvfp --enable-neon"
    CFLAGS="$CFLAGS -march=armv7-a -mfloat-abi=softfp -mfpu=neon"
    CFLAGS="$CFLAGS -ftree-vectorize -mvectorize-with-neon-quad"
    LDFLAGS="$LDFLAGS -Wl,--fix-cortex-a8"
    ;;
  x86)
    CONFIGURE_ARGS="$CONFIGURE_ARGS --enable-sse --enable-sse3"
    ;;
esac

CFLAGS="$CFLAGS -I$PREFIX/include"
LDFLAGS="$LDFLAGS -L$PREFIX/lib/$ABI"

export CFLAGS LDFLAGS

$CWD/configure \
  --prefix=$PREFIX \
  --bindir=$PREFIX/bin/$ABI \
  --libdir=$PREFIX/lib/$ABI \
  --shlibdir=$PREFIX/lib/$ABI \
  --enable-shared \
  --enable-static \
  --enable-pic \
  --enable-cross-compile \
  --target-os=android \
  --arch=$ARCH \
  --cross-prefix=$TOOLCHAIN_PREFIX- \
  --cc=$TOOLCHAIN_PREFIX-gcc \
  --cxx=$TOOLCHAIN_PREFIX-g++ \
  --ar=$TOOLCHAIN_PREFIX-ar \
  --nm=$TOOLCHAIN_PREFIX-nm \
  --sysroot=$TOOLCHAIN_DIR/sysroot \
  --extra-cflags="$CFLAGS" \
  --extra-ldflags="$LDFLAGS" \
  --disable-ffmpeg \
  --disable-ffplay \
  --disable-ffprobe \
  --disable-ffserver \
  --disable-encoders \
  --disable-protocols \
  --enable-protocol=file \
  --enable-protocol=http \
  --disable-indevs \
  --disable-outdevs \
  --disable-muxers \
  --disable-filters \
  $CONFIGURE_ARGS \
  || exit 1

make -j$BUILD_NUM_JOBS || exit 1
make install || exit 1

if [ "x$CUSTOM_OUTDIR" = "xno" ]; then
  rm -Rf $OUTDIR
fi

exit 0
