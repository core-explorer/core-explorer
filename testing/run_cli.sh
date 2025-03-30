#!/bin/sh

set -e
set -u
set -x

cd "${0%/*}"

echo RUN
LANG=C
export PATH=$PATH:$HOME/.cdx/bin
which node
node --version
cdx readelf --version

TOOLS="elfutils cdx" # binutils
FILES="build/*-*/*-*/dummy-buildid.pie build/*-*/*-*/dummy-buildid.exe"
OPTIONS="--segments --sections --debug-dump=info"


for t in $TOOLS; do
for f in $FILES; do
for o in $OPTIONS; do
./test_single_file.sh $t $o $f

done
done
done
