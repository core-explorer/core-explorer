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
if [ "$DWARFCLASS" = "dwarf64" ] && [ "$COMPRESS" != "none" ] ; then
	continue;
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
$CXX $TARGET $LIBFLAGS -g3 -g$DBG -g$DWARF -g$DWARFCLASS $GZ $OPT -fPIC -Wl,--build-id=sha1 -shared -o libshared-buildid.so $SOURCE/shared.cxx
$CXX $TARGET $LIBFLAGS -g3 -g$DBG -g$DWARF -g$DWARFCLASS $GZ $OPT -fPIC -Wl,--build-id=none -shared -o libshared-noid.so $SOURCE/shared.cxx
$CXX $TARGET $LIBFLAGS -g3 -g$DBG -g$DWARF -g$DWARFCLASS $GZ $OPT -fPIE  -o dummy.pie.o -c $SOURCE/dummy.cxx
$CXX $TARGET $LIBFLAGS -g3 -g$DBG -g$DWARF -g$DWARFCLASS $GZ $OPT -fno-PIE  -o dummy.exe.o -c $SOURCE/dummy.cxx

$CXX $TARGET $LIBFLAGS -g3 -g$DBG -g$DWARF -g$DWARFCLASS $GZ $LGZ $OPT -fPIE -pie -Wl,-z,relro -Wl,-z,now -Wl,-rpath=\$ORIGIN -Wl,--build-id=sha1 -o dummy-buildid.pie $SOURCE/dummy.cxx libshared-buildid.so
$CXX $TARGET $LIBFLAGS -g3 -g$DBG -g$DWARF -g$DWARFCLASS $GZ $LGZ $OPT -fPIE -pie -Wl,-z,relro -Wl,-z,now -Wl,-rpath=\$ORIGIN -Wl,--build-id=none -o dummy-noid.pie $SOURCE/dummy.cxx libshared-noid.so


$CXX $TARGET $LIBFLAGS -g3 -g$DBG -g$DWARF -g$DWARFCLASS $GZ $LGZ $OPT -fno-PIE -no-pie -Wl,-z,norelro -Wl,-rpath=\$ORIGIN -Wl,--build-id=sha1 -o dummy-buildid.exe $SOURCE/dummy.cxx libshared-buildid.so
$CXX $TARGET $LIBFLAGS -g3 -g$DBG -g$DWARF -g$DWARFCLASS $GZ $LGZ $OPT -fno-PIE -no-pie -Wl,-z,norelro -Wl,-rpath=\$ORIGIN -Wl,--build-id=none -o dummy-noid.exe $SOURCE/dummy.cxx libshared-noid.so



for DUMMY in dummy-buildid.exe dummy-noid.exe dummy-buildid.pie dummy-noid.pie ; do
    objcopy -N __JCR_END__ $DUMMY # java c runtime symbol defined on FreeBSD that aliases other symbols
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

cd ..
cd ..

done
done
done
done
done
cd ..
