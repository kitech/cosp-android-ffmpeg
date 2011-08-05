#!/bin/sh

usage()
{
  echo "Usage: $0 --prefix=PATH --android-ndk=PATH [--abi=ABI]"
  echo "  --prefix=PATH        installation prefix"
  echo "  --android-ndk=PATH   path to Android NDK installation"
  echo "                       Only CrystaX distribution accepted!"
  echo "                       See http://www.crystax.net/android/ndk.php"
  echo "  --abi=ABI            Optional ABI parameter"
  echo "                       Supported values are 'armeabi', 'armeabi-v7a' and 'x86'"
  echo "                       [default: armeabi]"
  exit $1
}

ABI=
ANDROID_NDK_ROOT=
PREFIX=

while true; do
  option=$1
  [ "x$option" = "x" ] && break
  case $option in
    -h | --help )
      usage 0
      ;;
    --abi=* )
      ABI=`expr "x$option" : "x--abi=\(.*\)"`
      ;;
    --abi )
      shift
      ABI=$1
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
      echo "ERROR: unknown option: $option"
      usage 1
      ;;
  esac
  shift
done

if [ "x$PREFIX" = "x" ]; then
  echo "ERROR: no installation prefix specified"
  usage 1
fi

echo "Using installation prefix: $PREFIX"

if [ "x$ANDROID_NDK_ROOT" = "x" ]; then
  echo "ERROR: no Android NDK specified"
  usage 1
fi

TOOLCHAIN_SCRIPT=$ANDROID_NDK_ROOT/build/tools/make-standalone-toolchain.sh
if [ ! -x $TOOLCHAIN_SCRIPT ]; then
  echo "Can't find make-standalone-toolchain.sh in $ANDROID_NDK_ROOT (corrupted NDK installation?)"
  exit 1
fi

echo "Using Android NDK: $ANDROID_NDK_ROOT"

TOOLCHAIN_VERSION=4.4.3

[ "x$ABI" = "x" ] && ABI=armeabi
case $ABI in
  armeabi* )
    TOOLCHAIN_PREFIX=arm-linux-androideabi
    TOOLCHAIN=arm-linux-androideabi-$TOOLCHAIN_VERSION
    ARCH=arm
    ;;
  x86 )
    TOOLCHAIN_PREFIX=i686-android-linux
    TOOLCHAIN=x86-$TOOLCHAIN_VERSION
    ARCH=x86
    ;;
  * )
    echo "ERROR: unknown abi: $ABI"
    usage 1
    ;;
esac

echo "Using CPU architecture: $ARCH"
echo "Using ABI: $ABI"
echo "Using toolchain: $TOOLCHAIN"

TOOLCHAIN_DIR=/tmp/android-toolchain/$USER/$TOOLCHAIN

NDK_ID_NEW=`ls -ld $ANDROID_NDK_ROOT 2>/dev/null | sha1sum | awk '{print $1}'`
NDK_ID_OLD=`cat $TOOLCHAIN_DIR/.done 2>/dev/null`
if [ "x$NDK_ID_OLD" != "x$NDK_ID_NEW" ]; then
  rm -Rf $TOOLCHAIN_DIR
  $TOOLCHAIN_SCRIPT --toolchain=$TOOLCHAIN --install-dir=$TOOLCHAIN_DIR || exit 1
  echo $NDK_ID_NEW >$TOOLCHAIN_DIR/.done || exit 1
fi

PATH=$TOOLCHAIN_DIR/bin:$PATH
export PATH

export ARCH ABI TOOLCHAIN_PREFIX
