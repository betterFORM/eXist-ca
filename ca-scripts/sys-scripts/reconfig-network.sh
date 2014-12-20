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

# source common script vars (generic, not OS specific vars and functions)
. $APPLIANCE_HOME/common.sh

# determine OS, release and distribution that we're running oo
OS_TYPE=`uname -s`
OS_RELEASE=`uname -r`
OS_HOST=`uname -n`

case "$OS_TYPE" in
    OpenBSD)
	THIS_OS=OpenBSD
	;;
    Linux)
	# determine Linux distribution
	#THIS_OS=Debian
	: ;;
    *)
	logmsg "OS $OS_TYPE yet unsupported"
	;;
esac

# source common script vars (OS specific vars and functions)
. $APPLIANCE_HOME/$THIS_OS/os-common.sh

err=0

# env sanity checks
if ! checkenv $REQ_ENV; then
    logmsg "ERROR - refuse to work on incomplete data"
    err=1
fi

### validate user provided input data

# validate passed $IF_NAME exists

# validate passed $IF_DHCP is boolean



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

