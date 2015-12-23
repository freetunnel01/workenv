#!/bin/bash
set -e
set -x


PREFIX=$HOME/php-test
WGET=wget
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
$WGET -c -O openssl-1.0.2e.tar.gz http://openssl.org/source/openssl-1.0.2e.tar.gz
rm -fr openssl-1.0.2e
tar zxf openssl-1.0.2e.tar.gz
cd openssl-1.0.2e
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

# cmake
cd $TOP
$WGET -c -O cmake-3.3.2.tar.gz https://cmake.org/files/v3.3/cmake-3.3.2.tar.gz
rm -fr cmake-3.3.2
tar zxf cmake-3.3.2.tar.gz
cd cmake-3.3.2
./configure --prefix=$PREFIX
make -j LDFLAGS="-Wl,-rpath,$PREFIX/lib "
make install
cd $TOP

# mariadb
cd $TOP
#$WGET -c -O https://downloads.mariadb.org/f/mariadb-10.1.8/source/mariadb-10.1.8.tar.gz/from/http%3A/mirror.jmu.edu/pub/mariadb/?serve
#$WGET -c -O mariadb-10.1.8.tar.gz 'https://downloads.mariadb.org/interstitial/mariadb-10.1.8/source/mariadb-10.1.8.tar.gz/from/http%3A//mirrors.opencas.cn/mariadb/'
$WGET -c -O mariadb-10.1.8.tar.gz http://mirrors.opencas.cn/mariadb//mariadb-10.1.8/source/mariadb-10.1.8.tar.gz
rm -fr mariadb-10.1.8
tar zxf mariadb-10.1.8.tar.gz
cd mariadb-10.1.8
find . -type f|xargs sed -i -e 's/-fuse-linker-plugin//g'
cmake . \
-DCMAKE_BUILD_TYPE=Release \
-DCMAKE_CXX_FLAGS=-O3 \
-DCMAKE_C_FLAGS=-O3 \
-DCMAKE_CXX_FLAGS_RELEASE='-O3' \
-DCMAKE_C_FLAGS_RELEASE='-O3' \
-DCMAKE_INSTALL_PREFIX=$PREFIX \
-DINSTALL_SYSCONFDIR=$PREFIX/etc \
-DINSTALL_SYSCONF2DIR=$PREFIX/etc/my.cnf.d \
-DMYSQL_DATADIR=$PREFIX/var/mysql/data \
-DOPENSSL_CRYPTO_LIBRARY=$PREFIX/lib/libcrypto.so \
-DOPENSSL_INCLUDE_DIR=$PREFIX/include \
-DOPENSSL_SSL_LIBRARY=$PREFIX/lib/libssl.so \
-DCRYPTO_LIBRARY=$PREFIX/lib/libcrypto.so \
-DCMAKE_MAKE_PROGRAM=make \
-DCMAKE_LINKER=gcc \
-DCMAKE_SKIP_RPATH=ON \
-DCMAKE_VERBOSE_MAKEFILE=ON \
-DWITH_UNIT_TESTS=OFF \
-DWITH_SSL=yes
make -j LDFLAGS="-Wl,-rpath,$PREFIX/lib " VERBOSE=1
make install
rm -fr $PREFIX/etc/my.cnf $PREFIX/data
cd $PREFIX
$PREFIX/scripts/mysql_install_db --datadir=$PREFIX/data
find $PREFIX/support-files/ -type f -name "*.cnf"|xargs sed -ie "s@\(socket.*=[^/]*\)/.*@\1$PREFIX/data/mysql.sock@g"
find $PREFIX/support-files/ -type f -name "*.cnf"|xargs sed -i "/\[mysqld\]/adatadir=$PREFIX/data\nuser=$USER\nwait-timeout=30\nbind-address = 127.0.0.1\n\n\n"
cp $PREFIX/support-files/my-small.cnf $PREFIX/etc/my.cnf
cd $TOP

# apr
cd $TOP
$WGET -c -O apr-1.5.2.tar.gz http://mirrors.cnnic.cn/apache/apr/apr-1.5.2.tar.gz
rm -fr apr-1.5.2
tar zxf apr-1.5.2.tar.gz
cd apr-1.5.2
./configure --prefix=$PREFIX
make -j LDFLAGS="-Wl,-rpath,$PREFIX/lib "
make install
cd $TOP

# apr-iconv
cd $TOP
$WGET -c -O apr-iconv-1.2.1.tar.gz http://mirrors.cnnic.cn/apache/apr/apr-iconv-1.2.1.tar.gz
rm -fr apr-iconv-1.2.1
tar zxf apr-iconv-1.2.1.tar.gz
cd apr-iconv-1.2.1
./configure --prefix=$PREFIX --with-apr=$PREFIX
make -j LDFLAGS="-Wl,-rpath,$PREFIX/lib "
make install
cd $TOP

# apr-utils
cd $TOP
$WGET -c -O apr-util-1.5.4.tar.gz http://mirrors.cnnic.cn/apache/apr/apr-util-1.5.4.tar.gz
rm -fr apr-util-1.5.4
tar zxf apr-util-1.5.4.tar.gz
cd apr-util-1.5.4
./configure --prefix=$PREFIX --with-apr=$PREFIX
#./configure --prefix=$PREFIX --with-apr=$PREFIX --with-apr-iconv=$PREFIX
make -j LDFLAGS="-Wl,-rpath,$PREFIX/lib "
make install
cd $TOP

# httpd
cd $TOP
$WGET -c -O httpd-2.4.17.tar.gz http://mirrors.cnnic.cn/apache/httpd/httpd-2.4.17.tar.gz
rm -fr httpd-2.4.17
tar zxf httpd-2.4.17.tar.gz
cd httpd-2.4.17
./configure --prefix=$PREFIX --with-apr=$PREFIX --with-apr-util=$PREFIX --with-ssl=$PREFIX
make -j LDFLAGS="-Wl,-rpath,$PREFIX/lib "
make install
sed -i  '2aexport LANG=en_US.UTF-8' $PREFIX/bin/apachectl
sed -i  '3aexport PATH=$(dirname $(dirname $(readlink -f $0)))/bin:$PATH' $PREFIX/bin/apachectl
#sed -i  '/HTTPD=/aHTTPD="$(dirname $(dirname $(readlink -f $0)))/bin/apachectl -f $(dirname $(dirname $(readlink -f $0)))/etc/httpd/httpd.conf"' $PREFIX/bin/apachectl
#mv $PREFIX/conf $PREFIX/etc/httpd
cd $TOP

# libmcrypt
cd $TOP
#$WGET -c -O libmcrypt-2.5.8.tar.gz http://sourceforge.net/projects/mcrypt/files/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz/download
#$WGET -c -O libmcrypt-2.5.8.tar.gz http://kent.dl.sourceforge.net/project/mcrypt/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz
$WGET -c -O libmcrypt-2.5.8.tar.gz http://jaist.dl.sourceforge.net/project/mcrypt/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz
rm -fr libmcrypt-2.5.8
tar zxf libmcrypt-2.5.8.tar.gz
cd libmcrypt-2.5.8
./configure --prefix=$PREFIX
make -j LDFLAGS="-Wl,-rpath,$PREFIX/lib "
make install

# php
cd $TOP
#$WGET -c -O php-7.0.0.tar.gz http://php.net/distributions/php-7.0.0.tar.gz
$WGET -c -O php-7.0.0.tar.gz http://cn2.php.net/distributions/php-7.0.0.tar.gz
rm -fr php-7.0.0
tar zxf php-7.0.0.tar.gz
cd php-7.0.0
./configure --prefix=$PREFIX \
--enable-shared \
--enable-fpm \
--enable-soap \
--enable-mbstring \
--enable-sockets \
--enable-exif \
--with-apxs2=$PREFIX/bin/apxs \
--with-mcrypt=$PREFIX \
--with-mysql=$PREFIX \
--with-config-file-path=$PREFIX/etc/ \
--with-config-file-scan-dir=$PREFIX/etc/php.d 
make -j LDFLAGS="-Wl,-rpath,\$ORIGIN/lib "
make install

mkdir -p $PREFIX/etc/php.d
cp php.ini-production $PREFIX/etc/php.ini
sed -i -e '/^session.save_handler/asession.save_path=/tmp' $PREFIX/etc/php.ini

chmod +x sapi/fpm/init.d.php-fpm
mkdir -p $PREFIX/share/php/script
cp sapi/fpm/init.d.php-fpm $PREFIX/share/php/script
sed -ie 's/^;pid/pid/g' $PREFIX/etc/php-fpm.conf.default
cp $PREFIX/etc/php-fpm.conf.default $PREFIX/etc/php-fpm.conf


cat >$PREFIX/conf/extra/httpd-php-module.conf<<ENDL
# to enable apache modules
# please add/include this lines for apache config files
DirectoryIndex index.html index.php
<FilesMatch \.php$>
    SetHandler application/x-httpd-php
</FilesMatch>
ENDL
echo Include conf/extra/httpd-php-module.conf >> $PREFIX/conf/httpd.conf

cat >$PREFIX/conf/extra/php-fcgi.conf<<ENDL
# to enable apache fcgi proxy forward
# please add/include this lines for apache config files
ProxyPassMatch /*.php fcgi://127.0.0.1:9000$PREFIX/var/httpd/htdocs/
ENDL
cd $TOP


# pydio
cd $TOP
#$WGET -c -O pydio-core-6.0.8.tar.gz http://sourceforge.net/projects/ajaxplorer/files/pydio/stable-channel/6.0.8/pydio-core-6.0.8.tar.gz/download
#$WGET -c -O pydio-core-6.0.8.tar.gz http://kent.dl.sourceforge.net/project/ajaxplorer/pydio/stable-channel/6.0.8/pydio-core-6.0.8.tar.gz
$WGET -c -O pydio-core-6.0.8.tar.gz http://jaist.dl.sourceforge.net/project/ajaxplorer/pydio/stable-channel/6.0.8/pydio-core-6.0.8.tar.gz
tar -C $PREFIX/htdocs -zxf pydio-core-6.0.8.tar.gz
mv $PREFIX/htdocs/pydio{-core-6.0.8,}
cd $TOP


echo -e "\n\n\necho build success !\n\n\n\n"



