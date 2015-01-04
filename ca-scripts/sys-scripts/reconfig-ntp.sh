#!/bin/sh

# modify ntpd configuration
#
# The following environment vars need to be passed from the caller 
# (vars may have no value, but must be present in the environment):
#   APPLIANCE_HOME
#   NTP_SRV1
#   NTP_SRV2
#   NTP_SRV3
#
# This script returns the following exit codes:
#   0  - success
#   1  - fail: parameter problem
#   2  - fail: reconfig ntp

[ -n "$DEBUG" ] && set -x

# required env vars as documented above
export REQ_ENV="\
 APPLIANCE_HOME \
 NTP_SRV1 \
 NTP_SRV3 \
 NTP_SRV3 \
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
    err=1
fi

### validate user provided input data

# cleanup obscure chars out of passed Common Name, for use as file name
SRV1=`echo "$NTP_SRV1" | tr -cd '[:alnum:].-'`
SRV2=`echo "$NTP_SRV2" | tr -cd '[:alnum:].-'`
SRV3=`echo "$NTP_SRV3" | tr -cd '[:alnum:].-'`

# err out with exit code 1 (parameter problem)
if [ $err -ne 0 ]; then
    logmsg "ERROR reconfig network: parameter problem"
    #printf "<XXX/>"
    exit 1
fi


# call OS specific function to reconfigzre and restart ntpd
# this function is defined in $OS/os-common.sh
$FAKE reconfig_ntpd $SRV1 $SRV2 $SRV3

if [ $? -ne 0 ]; then
    logmsg "ERROR - reconfiguring ntpd"
    exit 2
fi

exit 0
