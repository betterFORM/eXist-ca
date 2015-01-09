#!/bin/sh

# bundle OpenVPN client configuration files for a user
#
# The following environment vars need to be passed from the caller 
# (vars may have no value, but must be present in the environment):
#   EXISTCA_CANAME
#   EXISTCA_CERTNAME
#   OPENVPN_VPNNAME
#   PKI_BASE
#   APPLIANCE_HOME
#
# This script returns the following exit codes:
#   0  - success
#   1  - fail: parameter problem
#   2  - fail: bundle OpenVPN client config

[ -n "$DEBUG" ] && set -x

# required env vars as documented above
export REQ_ENV="\
 EXISTCA_CANAME \
 EXISTCA_CERTNAME \
 OPENVPN_VPNNAME \
 PKI_BASE \
 APPLIANCE_HOME \
"

#FAKE=echo

err=0

# source common script vars (generic, not OS specific vars and functions)
. $EXISTCA_HOME/script-vars.sh

OSDIR=`determine_osdir`
if [ -z "$OSDIR" ]; then
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

# cleanup obscure chars out of passed CA name, for use as file name
THIS_VPN=`echo "$OPENVPN_VPNNAME" | tr -cd '[:alnum:]'`

# cleanup obscure chars out of passed CA name, for use as file name
THIS_CA=`echo "$EXISTCA_CANAME" | tr -cd '[:alnum:]'`

# cleanup obscure chars out of passed Common Name, for use as file name
THIS_CN=`echo "$EXISTCA_CERTNAME" | tr -cd '[:alnum:].-'`

# err out with exit code 1 (parameter problem)
if [ $err -ne 0 ]; then
    logmsg "ERROR \"$THIS_VPN\" - bundling client VPN config: parameter problem"
    exit 1
fi

TMPDIR=`mktemp -d`
CLIENT_P12=$PKI_BASE/$THIS_CA/private/${THIS_CN}.p12
CLIENT_CONF=$OPENVPN_DIR/$THIS_VPN/client.ovpn
TA_KEY=$OPENVPN_DIR/$THIS_VPN/ta.key

sed -e "s|CLIENT.p12|${THIS_CN}.p12|;" <$CLIENT_CONF >$TMPDIR/${THIS_VPN}.ovpn
# 
for f in $CLIENT_P12 $TA_KEY; do
    if [ -f $f ]; then
	cp $f $TMPDIR/
    else
	logmsg "ERROR - file \"$f\" not found"
	err=1
    fi
done

cd $TMPDIR && zip -r /tmp/openvpn-${THIS_CN}.zip * || err=1
cd /tmp && rm -rf $TMPDIR

# err out with exit code 1 (parameter problem)
if [ $err -ne 0 ]; then
    logmsg "ERROR \"$THIS_VPN\" - failed to bundle client VPN config"
    exit 2
fi

