#!/bin/sh

cd `dirname $0` || exit 1

. build/cosp-android-common.sh || exit 1

export PREFIX ARCH

OUTDIR=$OUTDIR/ffmpeg

CWD=`pwd`
mkdir -p $OUTDIR || exit 1
cd $OUTDIR || exit 1

CFLAGS="-O3 -fpic -DANDROID -fasm -Wno-psabi -fno-short-enums -fno-strict-aliasing -finline-limit=300"
CFLAGS="$CFLAGS -I$TOOLCHAIN_DIR/sysroot/usr/include"
CFLAGS="$CFLAGS -DHAVE_SYS_UIO_H=1"

$CWD/configure \
  --prefix=$PREFIX \
  --bindir=$PREFIX/bin/$ABI \
  --libdir=$PREFIX/lib/$ABI \
  --shlibdir=$PREFIX/lib/$ABI \
  --enable-shared \
  --enable-static \
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
  --disable-everything \
  --enable-demuxer=mov \
  --enable-demuxer=h264 \
  --disable-ffplay \
  --enable-protocol=file \
  --enable-avformat \
  --enable-avcodec \
  --enable-decoder=rawvideo \
  --enable-decoder=mjpeg \
  --enable-decoder=h263 \
  --enable-decoder=mpeg4 \
  --enable-decoder=h264 \
  --enable-parser=h264 \
  --disable-network \
  --enable-zlib \
  --disable-avfilter \
  --disable-avdevice \
  || exit 1

make -j$BUILD_NUM_JOBS || exit 1
make install || exit 1

if [ "x$CUSTOM_OUTDIR" = "xno" ]; then
  rm -Rf $OUTDIR
fi

exit 0
