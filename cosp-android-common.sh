#!/bin/sh

SUPPORTED_ABIS="armeabi armeabi-v7a x86"
SUPPORTED_TOOLCHAIN_VERSIONS="4.4.3 4.6.3"

ANDROID_NDK_ROOT=
PREFIX=/opt/cosp
ABI=armeabi
TOOLCHAIN_VERSION=4.4.3
OUTDIR=

usage()
{
  echo "Usage: $0 [options] <ndk-dir>"
  echo ""
  echo "This is build script allowing build COSP android projects"
  echo "WARNING: Only CrystaX NDK accepted! See http://www.crystax.net/android/ndk for details"
  echo ""
  echo "Parameters:"
  echo "  <ndk-dir>              Path to Android NDK"
  echo ""
  echo "Valid options (defaults are in brackets):"
  echo ""
  echo "  --prefix=<path>        Installation prefix [$PREFIX]"
  echo "  --abi=<abi>            Optional ABI parameter [$ABI]"
  echo "                         Supported values: $SUPPORTED_ABIS"
  echo "  --toolchain=<version>  Optional toolchain version [$TOOLCHAIN_VERSION]"
  echo "                         Supported values: $SUPPORTED_TOOLCHAIN_VERSIONS"
  echo "  --build-out=<path>     Set build directory"
  exit $1
}

HOST_OS=`uname -s | tr '[A-Z]' '[a-z]'`
case $HOST_OS in
  darwin*|freebsd*)
    HOST_TAG=darwin-x86
    ;;
  linux* )
    HOST_TAG=linux-x86
    ;;
  cygwin*|mingw* )
    HOST_TAG=windows
    ;;
  * )
    echo "ERROR: Unsupported OS detected: $HOST_OS" >&2
    exit 1
    ;;
esac
export HOST_TAG

case "$HOST_OS" in
    linux* )
        HOST_NUM_CPUS=`cat /proc/cpuinfo | grep processor | wc -l`
        ;;
    darwin*|freebsd* )
        HOST_NUM_CPUS=`sysctl -n hw.ncpu`
        ;;
    cygwin*|mingw*)
        HOST_NUM_CPUS=$NUMBER_OF_PROCESSORS
        ;;
    *)  # let's play safe here
        HOST_NUM_CPUS=1
esac
export HOST_NUM_CPUS

# Define BUILD_NUM_JOBS as the double of HOST_NUM_CPUS. This is used to
# run Make commands in parralles, as in 'make -j$BUILD_NUM_JOBS'
#
BUILD_NUM_JOBS=`expr $HOST_NUM_CPUS \* 2`
export BUILD_NUM_JOBS

if [ "x$1" = "x" ]; then
  usage 0
fi

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
    --toolchain=* )
      TOOLCHAIN_VERSION=`expr "x$option" : "x--toolchain=\(.*\)"`
      ;;
    --toolchain )
      shift
      TOOLCHAIN_VERSION=$1
      ;;
    --build-out=* )
      OUTDIR=`expr "x$option" : "x--build-out=\(.*\)"`
      ;;
    --build-out )
      shift
      OUTDIR=$1
      ;;
    -* )
      echo "ERROR: unknown option: $option" >&2
      usage 1
      ;;
    * )
      ANDROID_NDK_ROOT=$1
      ;;
  esac
  shift
done

if [ "x$PREFIX" = "x" ]; then
  echo "ERROR: no installation prefix specified" >&2
  usage 1
fi

if [ ! -d $PREFIX ]; then
  mkdir -p $PREFIX
  if [ $? -ne 0 ]; then
    echo "ERROR: can't create prefix directory $PREFIX" >&2
    exit 1
  fi
fi

touch $PREFIX/.dummy
RET=$?
rm -f $PREFIX/.dummy 2>/dev/null
if [ $RET -ne 0 ]; then
  echo "ERROR: looks like $PREFIX is not writable" >&2
  exit 1
fi

echo "Using installation prefix: $PREFIX"

if [ "x$ANDROID_NDK_ROOT" = "x" ]; then
  echo "ERROR: no Android NDK specified" >&2
  usage 1
fi

TOOLCHAIN_SCRIPT=$ANDROID_NDK_ROOT/build/tools/make-standalone-toolchain.sh
if [ ! -x $TOOLCHAIN_SCRIPT ]; then
  echo "Can't find make-standalone-toolchain.sh in $ANDROID_NDK_ROOT (corrupted NDK installation?)"
  exit 1
fi

echo "Using Android NDK: $ANDROID_NDK_ROOT"

echo $SUPPORTED_ABIS | grep -q $ABI
if [ $? -ne 0 ]; then
  echo "ERROR: wrong abi specified: $ABI" >&2
  echo "       Supported values: $SUPPORTED_ABIS"
  exit 1
fi

echo "Using ABI: $ABI"

echo $SUPPORTED_TOOLCHAIN_VERSIONS | grep -q $TOOLCHAIN_VERSION
if [ $? -ne 0 ]; then
  echo "ERROR: wrong toolchain version: $TOOLCHAIN_VERSION." >&2
  echo "       Supported values: $SUPPORTED_TOOLCHAIN_VERSIONS"
  exit 1
fi

echo "Using toolchain version: $TOOLCHAIN_VERSION"

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
esac

echo "Using CPU architecture: $ARCH"
echo "Using toolchain: $TOOLCHAIN"

if [ "x$USER" = "x" ]; then
  USER=$USERNAME
fi
if [ "x$USER" = "x" ]; then
  USER=$$
fi
export USER

SHA1SUM=
for p in sha1sum gsha1sum; do
  which $p >/dev/null 2>&1 || continue
  SHA1SUM=$p
  break
done

OPENSSL=openssl

AWK=$ANDROID_NDK_ROOT/prebuilt/$HOST_TAG/bin/awk$EXE_EXT
if [ ! -f $AWK ]; then
  AWK=awk
fi

checksum()
{
  if [ "x$SHA1SUM" != "x" ]; then
    $SHA1SUM | $AWK '{print $1}'
  elif [ "x$OPENSSL" != "x" ]; then
    $OPENSSL sha1 | $AWK '{print $2}'
  else
    echo "ERROR: can't calculate checksum! Install sha1sum or openssl utility and try again" >&2
    exit 1
  fi
}

TOOLCHAIN_DIR=/tmp/android-toolchain-$ARCH-$TOOLCHAIN_VERSION-$USER

#NDK_ID_NEW=`tar cf - $ANDROID_NDK_ROOT 2>/dev/null | checksum`
NDK_ID_NEW=`ls -ld $ANDROID_NDK_ROOT 2>/dev/null | checksum`
NDK_ID_OLD=`cat $TOOLCHAIN_DIR/.done 2>/dev/null`
if [ "x$NDK_ID_OLD" != "x$NDK_ID_NEW" ]; then
  rm -Rf $TOOLCHAIN_DIR
  $TOOLCHAIN_SCRIPT --arch=$ARCH --toolchain=$TOOLCHAIN --install-dir=$TOOLCHAIN_DIR || exit 1
  echo $NDK_ID_NEW >$TOOLCHAIN_DIR/.done || exit 1
fi

PATH=$TOOLCHAIN_DIR/bin:$PATH
export PATH

export ANDROID_NDK_ROOT ARCH ABI TOOLCHAIN_PREFIX TOOLCHAIN_VERSION TOOLCHAIN

if [ "x$OUTDIR" = "x" ]; then
  OUTDIR=/tmp/cosp-android-$ARCH-$TOOLCHAIN_VERSION-$USER
  CUSTOM_OUTDIR=no
else
  CUSTOM_OUTDIR=yes
fi
export OUTDIR CUSTOM_OUTDIR
