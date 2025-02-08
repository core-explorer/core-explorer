#!/bin/bash
set -e
set -u
set -x
echo PREPARE

mkdir -p build
cd build
g++ -g3 -ggdb -gz -O1 -fPIC -shared -o libshared.so ../source/shared.cxx
g++ -g3 -ggdb -O1 -fPIE  -o dummy.o -c ../source/dummy.cxx
g++ -g3 -ggdb -O1 -fno-PIE -no-pie -Wl,-z,relro -Wl,-z,now -Wl,-rpath=\$ORIGIN -o dummy ../source/dummy.cxx libshared.so
g++ -g3 -ggdb -O1 -fPIE -Wl,-rpath=$(pwd) -Wl,--compress-debug-sections=zstd -o dummy.pie dummy.o libshared.so 
objcopy --only-keep-debug dummy dummy.dbg
objcopy --strip-debug dummy dummy.stripped
objcopy --add-gnu-debuglink=dummy.dbg dummy.stripped
gdb -batch -ex r -ex "gen dummy.core" -ex kill -ex q --args dummy.stripped
cd ..

