#!/bin/sh

# setup an appliance: install and configure all required software
#
# The following environment vars need to be passed from the caller 
# (vars may have no value, but must be present in the environment):
#   APPLIANCE_HOME
#
# This script returns the following exit codes:
#   0  - success
#   1  - fail: parameter problem
#   2  - fail: OpenVPN config

[ -n "$DEBUG" ] && set -x

# required env vars as documented above
export REQ_ENV="\
 APPLIANCE_HOME \
"

#FAKE=echo

err=0

# source common script vars (generic, not OS specific vars and functions)
. $APPLIANCE_HOME/common.sh

OSDIR=`determine_osdir`
if [ -n "$OSDIR" ]; then
    logmsg "ERROR - can not determine OS"
    err=1
else
    # source common script vars (OS specific vars and functions)
    . $APPLIANCE_HOME/$OSDIR/os-common.sh
fi

# env sanity checks
if ! checkenv $REQ_ENV; then
    echo "ERROR - refuse to work on incomplete data"
    exit 1
fi


### validate user provided input data

INSTALL_BASE=/usr/local
#INSTALL_BASE=/opt
EXIST_DIST=http://www.example.com/x.y.z

mkdir -p $INSTALL_BASE || err=1

# fetch and install utils (wget, zip/unzip)
UTILS="unzip wget zip"
for p in $UTILS; do
    logmsg "installing package $p"
    # OS specific function defined in $OSDIR/os-common.sh
    install_pkg $p || err=1
done

# fetch and install Java
install_pkg java || err=1

# fetch and install eXist software
#cd $INSTALL_BASE && wget $EXIST_DIST && tar zxf ...

# fetch and install eXistCA xar
#...

# enable and start eXist
#...

# enable and start NTP daemon

# install and start OpenVPN
install_pkg openvpn || err=1


