#!/bin/bash

set -x 
set -e

if [ -z "$SOURCE_DIR" ] ; then
    echo "Expected SOURCE_DIR in environment"
    exit 1
fi
if [ -z "$BUILD_DIR" ] ; then
    echo "Expected BUILD_DIR in environment"
    exit 1
fi

if test -d $BUILD_DIR ; then
    rm -rf $BUILD_DIR/*
fi

# SETUP development environment
yum groupinstall -y 'Development Tools'
if ! rpm -q gtk2-devel &> /dev/null ; then
    # while we do not link to these libraries they are 
    # needed for 'autogen.sh' to work correctly.
    yum install -y gtk2-devel
fi

# build web100 userland library for NDT
pushd $SOURCE_DIR/web100-userland
    patch -p1 < $SOURCE_DIR/conf/web100_userland-1.8-vsys.patch 
    ./autogen.sh
    ./configure --prefix=$BUILD_DIR/build  --disable-gtk2 --disable-gtktest
    make
    make install
popd

# build NPAD
pushd $SOURCE_DIR/npad
    export LD_LIBRARY_PATH=/home/iupui_npad/build/lib/
    export PYTHONPATH=/home/iupui_npad/build/lib/python2.6/site-packages/
    cp $SOURCE_DIR/conf/config.xml ./
    ./config.py -a
    (cd pathdiag; make saveswig)
    make
    make install
popd
 
# install init scripts
cp -r $SOURCE_DIR/init $BUILD_DIR/

# copy the configuration directory
cp -r $SOURCE_DIR/conf $BUILD_DIR/conf
# this file will be generated by initialize.sh
rm -f $BUILD_DIR/VAR/www/index.html
# this is the template from which index.html is generated.
cp $SOURCE_DIR/npad/diag_form.html $BUILD_DIR/conf/
#mv    $BUILD_DIR/VAR/www/diag_form.html $BUILD_DIR/conf/

# try to preserve backward compatibility with filenames/purpose
# NOTE: version file does not exist yet.  it's created after prepare.sh
#cp -f $BUILD_DIR/version $BUILD_DIR/VAR/www/tartime.txt

# log copying
cp -f $SOURCE_DIR/bin/redisplay.py $BUILD_DIR/build/
cp -f $SOURCE_DIR/conf/favicon.ico $BUILD_DIR/VAR/www/

# sidestream
cp -f $SOURCE_DIR/sidestream/doside $BUILD_DIR/build/bin
cp -f $SOURCE_DIR/sidestream/exitstats.py $BUILD_DIR/build/bin
cp -f $SOURCE_DIR/sidestream/tdump8000.py $BUILD_DIR/build/bin
cp -f $SOURCE_DIR/sidestream/mkSample.py $BUILD_DIR/build/bin

# ensure environment variables point to the build/* directory
cat <<\EOF > $BUILD_DIR/.bash_profile
source /etc/mlab/slice-functions
export PATH=$PATH:$SLICEHOME/build/bin:$SLICEHOME/build
export LD_LIBRARY_PATH=$SLICEHOME/build/lib
export PYTHONPATH=$SLICEHOME/build/lib/python2.6/site-packages
EOF
# generate a global config file for easy import
cat <<\EOF > $BUILD_DIR/conf/config.sh
RSYNCDIR=/var/spool/iupui_npad
RSYNCDIR_SS=/var/spool/iupui_npad/SideStream
RSYNCDIR_NPAD=/var/spool/iupui_npad/NPAD.v1

# read local values into variables
MYNODE=`cat $SLICEHOME/VAR/MYNODE 2> /dev/null`
MYADDR=`cat $SLICEHOME/VAR/MYADDR 2> /dev/null`
MYFQDN=`cat $SLICEHOME/VAR/MYFQDN 2> /dev/null`
MYLOCATION=`cat $SLICEHOME/VAR/MYLOCATION 2> /dev/null`
EOF
