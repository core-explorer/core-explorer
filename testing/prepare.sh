#!/bin/bash
set -e
set -u
set -x
echo PREPARE
ARCHITECTURES="x86_64 i686"
SOURCE=$(pwd)/source
mkdir -p build
cd build

for ARCH in $ARCHITECTURES ; do
mkdir -p $ARCH
CXX=$ARCH-linux-gnu-g++
cd $ARCH
$CXX -g3 -ggdb -gz -O1 -fPIC -shared -o libshared.so $SOURCE/shared.cxx
$CXX -g3 -ggdb -O1 -fPIE  -o dummy.o -c $SOURCE/dummy.cxx
$CXX -g3 -ggdb -O1 -fno-PIE -no-pie -Wl,-z,relro -Wl,-z,now -Wl,-rpath=\$ORIGIN -o dummy $SOURCE/dummy.cxx libshared.so
$CXX -g3 -ggdb -O1 -fPIE -Wl,-rpath=$(pwd) -Wl,--compress-debug-sections=zstd -o dummy.pie dummy.o libshared.so 
$ARCH-linux-gnu-objcopy --only-keep-debug dummy dummy.dbg
$ARCH-linux-gnu-objcopy --strip-debug dummy dummy.stripped
$ARCH-linux-gnu-objcopy --add-gnu-debuglink=dummy.dbg dummy.stripped
gdb -batch -ex r -ex "gen dummy.core" -ex kill -ex q --args dummy.stripped
cd ..

done
cd ..