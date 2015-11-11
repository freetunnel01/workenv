#!/bin/bash
set -e
set -x


PREFIX=$HOME/git
#WGET=wget
WGET=true



export PATH=$PREFIX/bin:/opt/compiler/gcc-4.8.2/bin:$PATH
export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig:$PREFIX/lib64/pkgconfig



TOP=`dirname $0`
TOP=`readlink -f $TOP`

mkdir -p $PREFIX/lib64
ln -s -f lib64 $PREFIX/lib
mkdir -p $PREFIX/sbin
ln -s -f sbin $PREFIX/bin

# openssl
cd $TOP
$WGET -c -O openssl-1.0.2d.tar.gz http://openssl.org/source/openssl-1.0.2d.tar.gz
rm -fr openssl-1.0.2d
tar zxf openssl-1.0.2d.tar.gz
cd openssl-1.0.2d
./Configure --prefix=$PREFIX --openssldir=$PREFIX/etc/ssl linux-x86_64 shared
make -j
make install
cd $TOP

# curl
cd $TOP
$WGET -c -O curl-7.45.0.tar.gz http://curl.haxx.se/download/curl-7.45.0.tar.gz
rm -fr curl-7.45.0
tar zxf curl-7.45.0.tar.gz
cd curl-7.45.0
./buildconf
./configure --prefix=$PREFIX --with-ssl=$PREFIX
make -j
make install

# git
cd $TOP
$WGET -c -O git-2.6.2.tar.gz https://www.kernel.org/pub/software/scm/git/git-2.6.2.tar.gz
rm -fr git-2.6.2
tar zxf git-2.6.2.tar.gz
cd git-2.6.2
make configure
./configure --prefix=$PREFIX
make -j LDFLAGS="-Wl,-rpath,$PREFIX/lib "
make install
for F in `find $PREFIX/libexec/git-core -type f`
do
	f=$PREFIX/bin/${F##*/}
	mv $F $f
	ln -s $f $F
done
cd $TOP

