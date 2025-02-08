#!/bin/sh
set -e
set -u
set -x
echo RUN

export PATH=$PATH:$HOME/.cdx/bin
cdx-readelf --version

FILES=build/*

for f in $FILES; do
cdx server $f --get index.html > files.html
cdx server $f --get file/0/ > file.html
cdx server $f --get file/0/section/ > sections.html
set +e
tidy -e files.html
EXITCODE=$?
if [ "$EXITCODE" = "2" ] ; then
exit 1
fi
tidy -e file.html
EXITCODE=$?
if [ "$EXITCODE" = "2" ] ; then
exit 1
fi
tidy -e sections.html
EXITCODE=$?
if [ "$EXITCODE" = "2" ] ; then
exit 1
fi
set -e
done