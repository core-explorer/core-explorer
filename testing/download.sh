#!/bin/bash
set -e
set -u
set -x
echo DOWNLOAD

if llvm-readelf --version && eu-readelf --version && readelf --version && which ansi2txt && gdb --version && tidy --version ; then
true
else
sudo apt-get update
sudo apt-get install llvm elfutils binutils colorized-logs gdb g++ tidy 
fi
mkdir -p $HOME/.cdx/bin
if [ ! -e $HOME/.cdx/node-latest-linux-x64/bin/node ] ; then 
NODEVER=v23.7.0
wget https://nodejs.org/dist/$NODEVER/node-$NODEVER-linux-x64.tar.xz
tar xf node-$NODEVER-linux-x64.tar.xz && rm node-$NODEVER-linux-x64.tar.xz
mv node-$NODEVER-linux-x64 $HOME/.cdx/node-latest-linux-x64
ln -sf $HOME/.cdx/node-latest-linux-x64/bin/node $HOME/.cdx/bin/node
fi

cp ../cdx.js $HOME/.cdx/bin/
cp bin/* $HOME/.cdx/bin/
