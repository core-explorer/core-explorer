#!/bin/sh
set -e
set -u
set -x
echo PREPARE
HOST_ARCH="$(uname -m)"
HOST_SYSTEM="$(uname -o|sed 's+GNU/Linux+linux-gnu+g;s/FreeBSD/freebsd/g')"
BUILD_ARCHITECTURES="x86_64 i686 aarch64 riscv64" # arm
RUN_ARCHITECTURES="$HOST_ARCH"
SOURCE=$(pwd)/source
mkdir -p build
cd build

if [ "$HOST_ARCH" = "x86_64" ] || [ "$HOST_ARCH" = "amd64" ] ; then
RUN_ARCHITECTURES="$HOST_ARCH i686"
fi

if [ "$HOST_ARCH" = "aarch64" ] || [ "$HOST_ARCH" = "arm64" ] ; then
RUN_ARCHITECTURES="$HOST_ARCH arm"
fi



for RAW_ARCH in $BUILD_ARCHITECTURES ; do
ARCH=$RAW_ARCH-$HOST_SYSTEM
if [ "$ARCH" = "arm-linux-gnu" ] ; then
	ARCH="arm-linux-gnueabihf"
fi
for CC in clang gcc ; do
for DWARF in dwarf-4 dwarf-5 ; do
for DWARFCLASS in dwarf32 dwarf64 ; do
for COMPRESS in znone zlib zstd ; do
for OLEVEL in O0 O2 ; do
if [ "$RAW_ARCH" != "$HOST_ARCH" ] ; then
    if [ "$DWARFCLASS" = "dwarf64" ] ; then
    continue
    fi
    if [ "$COMPRESS" != "znone" ] ; then
    continue
    fi
fi

if [ "$DWARF" = "dwarf-4" ] && [ "$COMPRESS" != "znone" ] ; then
    continue
fi
if [ "$DWARFCLASS" = "dwarf64" ] && [ "$COMPRESS" != "znone" ] ; then
	continue;
fi

CXX=${CC}++
DBG=gdb
LIBFLAGS=""
TARGET=""
if [ "$CC" = "gcc" ] ; then
    if [ "$RAW_ARCH" != "$HOST_ARCH" ] ; then
    CXX=$ARCH-g++
    else
    CXX=g++
    fi
else
    CXX="clang++"    
    if [ "$RAW_ARCH" != "$HOST_ARCH" ] ; then
        TARGET="--target=$ARCH"
    else
    LIBFLAGS="-stdlib=libc++ -fuse-ld=lld"
    fi
fi

which $CXX || continue
if [ "$RAW_ARCH" = "riscv64" ] && [ "$CC" = "clang" ] ; then
	continue
fi
echo $CXX $TARGET
mkdir -p $ARCH
OPT=-$OLEVEL
cd $ARCH
DIR=$CC-$DWARF-$DWARFCLASS-$OLEVEL-$COMPRESS
mkdir -p ./$DIR
cd ./$DIR
GZ="-gz=$COMPRESS"
LGZ="-Wl,--compress-debug-sections=$COMPRESS"
if [ "$COMPRESS" = "znone" ] ; then
GZ=""
LGZ=""
fi
$CXX $TARGET $LIBFLAGS -g3 -g$DBG -g$DWARF -g$DWARFCLASS $GZ $OPT -fPIC -Wl,--build-id=sha1 -shared -o libshared-buildid.so $SOURCE/shared.cxx
$CXX $TARGET $LIBFLAGS -g3 -g$DBG -g$DWARF -g$DWARFCLASS $GZ $OPT -fPIC -Wl,--build-id=none -shared -o libshared-noid.so $SOURCE/shared.cxx
$CXX $TARGET $LIBFLAGS -g3 -g$DBG -g$DWARF -g$DWARFCLASS $GZ $OPT -fPIE  -o dummy.pie.o -c $SOURCE/dummy.cxx
$CXX $TARGET $LIBFLAGS -g3 -g$DBG -g$DWARF -g$DWARFCLASS $GZ $OPT -fno-PIE  -o dummy.exe.o -c $SOURCE/dummy.cxx

if [ "$RAW_ARCH" != "arm" ] ; then
$CXX $TARGET $LIBFLAGS -g3 -g$DBG -g$DWARF -g$DWARFCLASS $GZ $LGZ $OPT -fPIE -pie -Wl,-z,relro -Wl,-z,now -Wl,-rpath=\$ORIGIN -Wl,--build-id=sha1 -o dummy-buildid.pie $SOURCE/dummy.cxx libshared-buildid.so
$CXX $TARGET $LIBFLAGS -g3 -g$DBG -g$DWARF -g$DWARFCLASS $GZ $LGZ $OPT -fPIE -pie -Wl,-z,relro -Wl,-z,now -Wl,-rpath=\$ORIGIN -Wl,--build-id=none -o dummy-noid.pie $SOURCE/dummy.cxx libshared-noid.so
# eu-readelf --debug-dump=info on armhf binaries gets super confused by the $d symbols from compact unwind information
fi

$CXX $TARGET $LIBFLAGS -g3 -g$DBG -g$DWARF -g$DWARFCLASS $GZ $LGZ $OPT -fno-PIE -no-pie -Wl,-rpath=\$ORIGIN -Wl,--build-id=sha1 -o dummy-buildid.exe $SOURCE/dummy.cxx $SOURCE/shared.cxx
$CXX $TARGET $LIBFLAGS -g3 -g$DBG -g$DWARF -g$DWARFCLASS $GZ $LGZ $OPT -fno-PIE -no-pie -Wl,-rpath=\$ORIGIN -Wl,--build-id=none -o dummy-noid.exe $SOURCE/dummy.cxx $SOURCE/shared.cxx

RUN=0
for r in $RUN_ARCHITECTURES; do
if [ "$r" = "$RAW_ARCH" ] ; then
RUN=1
fi
done
if [ "$RUN" = "1" ] ; then
for DUMMY in dummy-buildid.exe dummy-noid.exe dummy-buildid.pie dummy-noid.pie ; do
    # elfutils helpfully tries to resolve addresses to symbols when printing debuginfo
    # we remove troublesome symbols to normalize output
    # it doesn't ignore notype symbols, it probably should
    objcopy -N __JCR_END__ $DUMMY # java c runtime symbol defined on FreeBSD
    objcopy -N _end $DUMMY
    objcopy --only-keep-debug $DUMMY $DUMMY.dbg
    objcopy --strip-debug $DUMMY $DUMMY.stripped
    objcopy --add-gnu-debuglink=$DUMMY.dbg $DUMMY.stripped

    if [ "$DBG" = "gdb" ] ; then
        gdb -batch -ex "set disable-randomization off" -ex r -ex "generate-core $DUMMY.gdb.core " -ex kill -ex q < /dev/null $DUMMY.stripped
    else
        if [ "$RAW_ARCH" = "$HOST_ARCH" ] ; then
            lldb -batch --one-line "settings set target.disable-aslr false" --one-line r --one-line "process save-core $DUMMY.lldb.core " --one-line kill --one-line q < /dev/null $DUMMY.stripped
        fi
    fi
done
fi

cd ..
cd ..

done
done
done
done
done
done
cd ..
