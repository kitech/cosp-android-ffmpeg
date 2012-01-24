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
  --enable-small \
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
  --disable-debug \
  --disable-avdevice \
  --disable-avfilter \
  --disable-postproc \
  --disable-swresample \
  --disable-swscale \
  --disable-everything \
  --enable-decoder=aac \
  --enable-decoder=adpcm_g726 \
  --enable-decoder=adpcm_ima_qt \
  --enable-decoder=adpcm_ms \
  --enable-decoder=alac \
  --enable-decoder=amrnb \
  --enable-decoder=ape \
  --enable-decoder=armwb \
  --enable-decoder=flac \
  --enable-decoder=gsm \
  --enable-decoder=gsm_ms \
  --enable-decoder=mp2 \
  --enable-decoder=mp3 \
  --enable-decoder=pam \
  --enable-decoder=pcm_alaw \
  --enable-decoder=pcm_bluray \
  --enable-decoder=pcm_dvd \
  --enable-decoder=pcm_f32be \
  --enable-decoder=pcm_f32le \
  --enable-decoder=pcm_f64be \
  --enable-decoder=pcm_f64le \
  --enable-decoder=pcm_mulaw \
  --enable-decoder=pcm_s16be \
  --enable-decoder=pcm_s16le \
  --enable-decoder=pcm_s16le_planar \
  --enable-decoder=pcm_s24be \
  --enable-decoder=pcm_s24le \
  --enable-decoder=pcm_s32be \
  --enable-decoder=pcm_s32le \
  --enable-decoder=pcm_s8 \
  --enable-decoder=pcm_s8_planar \
  --enable-decoder=pcm_u16be \
  --enable-decoder=pcm_u16le \
  --enable-decoder=pcm_u24be \
  --enable-decoder=pcm_u24le \
  --enable-decoder=pcm_u8 \
  --enable-decoder=pcm_ulaw \
  --enable-decoder=pcm_zork \
  --enable-decoder=tta \
  --enable-decoder=twinvq \
  --enable-decoder=vorbis \
  --enable-decoder=wavpack \
  --enable-decoder=wmapro \
  --enable-decoder=wmav1 \
  --enable-decoder=wmav2 \
  --enable-demuxer=aac \
  --enable-demuxer=aiff \
  --enable-demuxer=amr \
  --enable-demuxer=ape \
  --enable-demuxer=asf \
  --enable-demuxer=flac \
  --enable-demuxer=mov \
  --enable-demuxer=mp3 \
  --enable-demuxer=ogg \
  --enable-demuxer=pcm_alaw \
  --enable-demuxer=pcm_f32be \
  --enable-demuxer=pcm_f32le \
  --enable-demuxer=pcm_f64be \
  --enable-demuxer=pcm_f64le \
  --enable-demuxer=pcm_mulaw \
  --enable-demuxer=pcm_s16be \
  --enable-demuxer=pcm_s16le \
  --enable-demuxer=pcm_s24be \
  --enable-demuxer=pcm_s24le \
  --enable-demuxer=pcm_s32be \
  --enable-demuxer=pcm_s32le \
  --enable-demuxer=pcm_s8 \
  --enable-demuxer=pcm_u16be \
  --enable-demuxer=pcm_u16le \
  --enable-demuxer=pcm_u24be \
  --enable-demuxer=pcm_u24le \
  --enable-demuxer=pcm_u32be \
  --enable-demuxer=pcm_u32le \
  --enable-demuxer=pcm_u8 \
  --enable-demuxer=pcm_ulaw \
  --enable-demuxer=tta \
  --enable-demuxer=vqf \
  --enable-demuxer=wav \
  --enable-demuxer=wv \
  --enable-parser=aac \
  --enable-parser=flac \
  --enable-parser=mpegaudio \
  --enable-protocol=file \
  --enable-protocol=http \
  $CONFIGURE_ARGS \
  || exit 1

make -j$BUILD_NUM_JOBS || exit 1
make install || exit 1

if [ "x$CUSTOM_OUTDIR" = "xno" ]; then
  rm -Rf $OUTDIR
fi

exit 0
