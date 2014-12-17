#!/bin/sh

# modify jetty configuration
#
# The following environment vars need to be passed from the caller 
# (vars may have no value, but must be present in the environment):
#
# This script returns the following exit codes:
#   0  - success
#   1  - fail: parameter problem


# required env vars as documented above
export REQ_ENV="\
"

#FAKE=echo

# source common script vars
#. $EXISTCA_HOME/script-vars.sh

# env sanity checks
if ! checkenv $REQ_ENV; then
    echo "ERROR - refuse to work on incomplete data"
    exit 1
fi

OPENVPN_DIR=/etc/openvpn

# copy ca cert, server key and cert, and DH parameters

# copy and modify openvpn config

# restart openvpn
#/etc/rc.d/openvpn restart

