#!/bin/sh

ARCH=
ANDROID_NDK_ROOT=
PREFIX=

while true; do
  option=$1
  [ "x$option" = "x" ] && break
  case $option in
    --arch=* )
      ARCH=`expr "x$option" : "x--arch=\(.*\)"`
      ;;
    --arch )
      shift
      ARCH=$1
      ;;
    --android-ndk=* )
      ANDROID_NDK_ROOT=`expr "x$option" : "x--android-ndk=\(.*\)"`
      ;;
    --android-ndk )
      shift
      ANDROID_NDK_ROOT=$1
      ;;
    --prefix=* )
      PREFIX=`expr "x$option" : "x--prefix=\(.*\)"`
      ;;
    --prefix )
      shift
      PREFIX=$1
      ;;
    * )
      echo "Unknown option: $option"
      exit 1
      ;;
  esac
  shift
done

if [ "x$ANDROID_NDK_ROOT" = "x" ]; then
echo "No Android NDK specified (--android-ndk=PATH)"
exit 1
fi

TOOLCHAIN_SCRIPT=$ANDROID_NDK_ROOT/build/tools/make-standalone-toolchain.sh
if [ ! -x $TOOLCHAIN_SCRIPT ]; then
echo "Can't find make-standalone-toolchain.sh in $ANDROID_NDK_ROOT (corrupted NDK installation?)"
exit 1
fi

echo "Using Android NDK: $ANDROID_NDK_ROOT"

if [ "x$PREFIX" = "x" ]; then
  echo "No installation prefix specified (--prefix=PATH)"
  exit 1
fi

[ "x$ARCH" = "x" ] && ARCH=arm

TOOLCHAIN_VERSION=4.4.3

case $ARCH in
  arm )
    TOOLCHAIN_ABI=arm-linux-androideabi
    TOOLCHAIN=arm-linux-androideabi-$TOOLCHAIN_VERSION
    ABI=armeabi
    ;;
  x86 )
    TOOLCHAIN_ABI=i686-android-linux
    TOOLCHAIN=x86-$TOOLCHAIN_VERSION
    ABI=x86
    ;;
  * )
    echo "Unknown CPU architecture: $ARCH"
    exit 1
    ;;
esac

echo "Using CPU architecture: $ARCH"
echo "Using toolchain ABI: $TOOLCHAIN_ABI"

echo "Using installation prefix: $PREFIX"

TOOLCHAIN_DIR=/tmp/android-toolchain/$USER/$TOOLCHAIN

NDK_BUILT_FROM=`cat $TOOLCHAIN_DIR/.done 2>/dev/null`
if [ "x$NDK_BUILT_FROM" != "x$ANDROID_NDK_ROOT" ]; then
  rm -Rf $TOOLCHAIN_DIR
  $TOOLCHAIN_SCRIPT --toolchain=$TOOLCHAIN --install-dir=$TOOLCHAIN_DIR || exit 1
  echo $ANDROID_NDK_ROOT >$TOOLCHAIN_DIR/.done || exit 1
fi

PATH=$TOOLCHAIN_DIR/bin:$PATH
export PATH

export ARCH ABI TOOLCHAIN_ABI
