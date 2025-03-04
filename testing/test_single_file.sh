#! /bin/sh
set -e
set -u

TOOLNAME=$1
OPTION=$2
FILE=$3

TOOL=false
FILTER=""

if [ "$TOOLNAME" = "llvm" ] ; then
TOOL=llvm-readelf
elif [ "$TOOLNAME" = "binutils" ] ; then
TOOL="readelf --wide"
elif [ "$TOOLNAME" = "elfutils" ] ; then
TOOL=eu-readelf
elif [ "$TOOLNAME" = "cdx" ] ; then
true
else
echo "TOOL must be llvm, binutils, elfutils or cdx"
exit 1
fi

if [ "$TOOLNAME" = "cdx" ] ; then
cdx-readelf --color=always $OPTION $FILE > colored.tmp ; ansi2txt < colored.tmp > golden_$TOOLNAME.txt
else
$TOOL $OPTION $FILE > golden_$TOOLNAME.txt
fi

cdx-readelf --format=$TOOLNAME $OPTION $FILE > output_$TOOLNAME.txt

exec diff   --color golden_$TOOLNAME.txt output_$TOOLNAME.txt
