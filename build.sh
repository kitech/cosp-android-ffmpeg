#!/bin/sh

cd `dirname $0` || exit 1

. ./cosp-android-common.sh || exit 1

export PREFIX ARCH

OUTDIR=$OUTDIR/ffmpeg

CWD=`pwd`
mkdir -p $OUTDIR || exit 1
cd $OUTDIR || exit 1

CFLAGS="-O3 -fno-short-enums -fno-strict-aliasing"
CFLAGS="$CFLAGS -Wno-psabi -Wno-cast-qual -Wno-deprecated-declarations"

$CWD/configure \
  --prefix=$PREFIX \
  --bindir=$PREFIX/bin/$ABI \
  --libdir=$PREFIX/lib/$ABI \
  --shlibdir=$PREFIX/lib/$ABI \
  --enable-shared \
  --enable-static \
  --enable-pic \
  --disable-yasm \
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
  --disable-ffmpeg \
  --disable-ffplay \
  --disable-ffprobe \
  --disable-ffserver \
  --disable-encoders \
  --enable-protocol=file \
  --enable-protocol=http \
  --enable-avformat \
  --enable-avcodec \
  --disable-indevs \
  --disable-outdevs \
  --enable-zlib \
  --disable-bzlib \
  || exit 1

make -j$BUILD_NUM_JOBS || exit 1
make install || exit 1

if [ "x$CUSTOM_OUTDIR" = "xno" ]; then
  rm -Rf $OUTDIR
fi

exit 0
