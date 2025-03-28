#!/bin/sh
set -e
set -u
set -x
echo RUN
LANG=C
export PATH=$PATH:$HOME/.cdx/bin
cdx-readelf --version

TOOLS="elfutils cdx"
FILES=build/*-*/*-*/dummy-buildid.pie
OPTIONS="--segments --sections --debug-dump=info"


for t in $TOOLS; do
for f in $FILES; do
for o in $OPTIONS; do
./test_single_file.sh $t $o $f

done
done
done
