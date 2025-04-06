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

FILES="build/*-*/*-*/dummy-buildid.pie build/*-*/*-*/dummy-buildid.exe"
#if false ; then
TOOLS="elfutils cdx" # binutils
OPTIONS="--segments --sections --debug-dump=info"
for t in $TOOLS; do
    for f in $FILES; do
        for o in $OPTIONS; do
            ./test_single_file.sh $t $o $f
        done
    done
done
#fi

TOOLS="binutils cdx"
OPTIONS="--debug-dump=frames"
for t in $TOOLS; do
    for f in $FILES; do
        for o in $OPTIONS; do
            if  dirname $f | grep -c arm && basename $f | grep -c exe; then
            # no support for debug_frame at the moment
            continue;
            fi
            ./test_single_file.sh $t $o $f
        done
    done
done
