#!/bin/sh 

# reconfigure networking for a server or appliance
#
# The following environment vars need to be passed from the caller 
# (vars may have no value, but must be present in the environment):
#   APPLIANCE_HOME
#   IF_NAME
#
# This script returns the following exit codes:
#   0  - success
#   1  - fail: parameter problem
#   2  - fail: cert creation

[ -n "$DEBUG" ] && set -x

# required env vars as documented above
REQ_ENV="\
APPLIANCE_HOME \
IF_NAME \
"

#FAKE="echo"

# dump cert data as XML
dump_xml () {
#    printf "
#" >$EXISTCA_XMLOUT
}

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
    logmsg "ERROR - refuse to work on incomplete data"
    err=1
fi

### validate user provided input data

# validate passed $IF_NAME exists

# validate passed $IF_DHCP is boolean

# err out with exit code 1 (parameter problem)
if [ $err -ne 0 ]; then
    logmsg "ERROR reconfig network: parameter problem"
    printf "<XXX/>"
    exit 1
fi


###

if [ "$IF_DHCP" = yes ]; then
    if ! get_if_dhcp "$IF_NAME"; then
	# need to reconfig for DHCP
	set_if_dhcp "$IF_NAME"
#	reconfig_if "$IF_NAME"
    else
	logmsg "interface $IF_NAME already configured for DHCP"
    fi
else
    logmsg "manual network configuration yet unimplemented"
fi


