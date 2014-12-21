#!/bin/sh

# modify jetty configuration
#
# The following environment vars need to be passed from the caller 
# (vars may have no value, but must be present in the environment):
#   NTP_SRV1
#   NTP_SRV2
#   NTP_SRV3
#
# This script returns the following exit codes:
#   0  - success
#   1  - fail: parameter problem
#   2  - fail: reconfig ntp


# required env vars as documented above
export REQ_ENV="\
 NTP_SRV1 \
 NTP_SRV3 \
 NTP_SRV3 \
"

#FAKE=echo

# source common script vars
#. $EXISTCA_HOME/script-vars.sh

# env sanity checks
if ! checkenv $REQ_ENV; then
    echo "ERROR - refuse to work on incomplete data"
    exit 1
fi

### validate user provided input data

# cleanup obscure chars out of passed Common Name, for use as file name
SRV1=`echo -n "$NTP_SRV1" | tr -cd '[:alnum:].-'`
SRV2=`echo -n "$NTP_SRV2" | tr -cd '[:alnum:].-'`
SRV3=`echo -n "$NTP_SRV3" | tr -cd '[:alnum:].-'`

# call OS specific function to reconfigzre and restart ntpd
# this function is defined in $OS/os-common.sh
$FAKE reconfig_ntpd $SRV1 $SRV2 $SRV3

ret=$?
if [ $ret -ne 0 ]; then
    logmsg "ERROR - reconfiguring ntpd"
    exit 2
fi

exit 0
