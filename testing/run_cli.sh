#!/bin/sh
set -e
set -u
set -x
echo RUN

export PATH=$PATH:$HOME/.cdx/bin
cdx-readelf --version

TOOLS="llvm elfutils binutils cdx"
FILES=build/*/*
OPTIONS="-S --sections"


for t in $TOOLS; do
for f in $FILES; do
for o in $OPTIONS; do
./test_single_file.sh $t $o $f

done
done
done
