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
FILES_v5="build/*-*/*dwarf-5*/dummy-buildid.pie build/*-*/*dwarf-5*/dummy-buildid.exe"

if true ; then
TOOLS="elfutils"
OPTIONS="--debug-dump=info"
for t in $TOOLS; do
    for f in $FILES; do
        for o in $OPTIONS; do
            ./test_single_file.sh $t $o $f
        done
    done
done
fi
if true ; then
TOOLS="binutils "
OPTIONS="--debug-dump=frames"
for t in $TOOLS; do
    for f in $FILES; do
        for o in $OPTIONS; do
            ./test_single_file.sh $t $o $f
        done
    done
done
fi

TOOLS="binutils "
OPTIONS="--debug-dump=Ranges"
for t in $TOOLS; do
    for f in $FILES_v5; do
        for o in $OPTIONS; do
            ./test_single_file.sh $t $o $f
        done
    done
done
