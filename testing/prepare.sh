#!/bin/sh
set -e
set -u
set -x
echo PREPARE
HOST_ARCH="$(uname -m)"
HOST_SYSTEM="$(uname -o|sed 's+GNU/Linux+linux-gnu+g;s/FreeBSD/freebsd/g')"
ARCHITECTURES="$HOST_ARCH"
SOURCE=$(pwd)/source
mkdir -p build
cd build

if [ "$HOST_ARCH" = "x86_64" ] || [ "$HOST_ARCH" = "amd64" ] ; then
ARCHITECTURES="$HOST_ARCH i686"
fi

for RAW_ARCH in $ARCHITECTURES ; do
ARCH=$RAW_ARCH-$HOST_SYSTEM
for CC in clang gcc ; do
for DWARF in dwarf-4 dwarf-5 ; do
for DWARFCLASS in dwarf32 dwarf64 ; do
for COMPRESS in none zlib zstd ; do

if [ "$RAW_ARCH" != "$HOST_ARCH" ] ; then
    if [ "$DWARFCLASS" = "dwarf64" ] ; then
    continue
    fi
    if [ "$COMPRESS" != "none" ] ; then
    continue
    fi
fi

if [ "$DWARF" = "dwarf-4" ] && [ "$COMPRESS" != "none" ] ; then
    continue
fi

CXX=${CC}++
DBG=lldb
LIBFLAGS=""
TARGET=""
if [ "$CC" = "gcc" ] ; then
    if [ "$RAW_ARCH" != "$HOST_ARCH" ] ; then
    CXX=$ARCH-g++
    else
    CXX=g++
    fi
    DBG=gdb
else
    
    if [ "$RAW_ARCH" != "$HOST_ARCH" ] ; then
        TARGET="--target=$ARCH"
    else
    LIBFLAGS="-stdlib=libc++"
    fi
fi

which $CXX || continue
echo $CXX $TARGET
mkdir -p $ARCH
OPT=-O1
cd $ARCH
mkdir -p ./$CC-$DWARF-$DWARFCLASS-$COMPRESS
cd ./$CC-$DWARF-$DWARFCLASS-$COMPRESS
GZ="-gz=$COMPRESS"
LGZ="-Wl,--compress-debug-sections=$COMPRESS"
if [ "$COMPRESS" = "none" ] ; then
GZ=""
LGZ=""
fi
$CXX $TARGET $LIBFLAGS -g3 -g$DBG -g$DWARF -g$DWARFCLASS $GZ $OPT -fPIC -shared -o libshared.so $SOURCE/shared.cxx
$CXX $TARGET $LIBFLAGS -g3 -g$DBG -g$DWARF -g$DWARFCLASS $GZ $OPT -fPIE  -o dummy.o -c $SOURCE/dummy.cxx
$CXX $TARGET $LIBFLAGS -g3 -g$DBG -g$DWARF -g$DWARFCLASS $GZ $LGZ $OPT -fno-PIE -no-pie -Wl,-z,relro -Wl,-z,now -Wl,-rpath=\$ORIGIN -o dummy $SOURCE/dummy.cxx libshared.so
$CXX $TARGET $LIBFLAGS -g3 -g$DBG -g$DWARF -g$DWARFCLASS $GZ $LGZ $OPT -fno-PIE -no-pie -Wl,-z,relro -Wl,-z,now -Wl,-rpath=\$ORIGIN -Wl,--build-id -o dummy.buildid $SOURCE/dummy.cxx libshared.so
$CXX $TARGET $LIBFLAGS -g3 -g$DBG -g$DWARF -g$DWARFCLASS $GZ $LGZ $OPT -fPIE -pie -Wl,-rpath=$(pwd) $LGZ -o dummy.pie dummy.o libshared.so 
objcopy -N __JCR_END__ dummy.pie
objcopy --only-keep-debug dummy dummy.dbg
objcopy --strip-debug dummy dummy.stripped
objcopy --add-gnu-debuglink=dummy.dbg dummy.stripped
if [ "$DBG" = "gdb" ] ; then
gdb -batch -ex r -ex "generate-core dummy.gdb.core " -ex kill -ex q < /dev/null dummy.stripped
else
if [ "$RAW_ARCH" = "$HOST_ARCH" ] ; then
lldb -batch --one-line r --one-line "process save-core dummy.lldb.core " --one-line kill --one-line q < /dev/null dummy.stripped
fi
fi

cd ..
cd ..

done
done
done
done
done
cd ..
