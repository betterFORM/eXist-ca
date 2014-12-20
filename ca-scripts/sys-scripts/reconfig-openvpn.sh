#!/bin/sh

# modify jetty configuration
#
# The following environment vars need to be passed from the caller 
# (vars may have no value, but must be present in the environment):
#   OPENVPN_VPNNAME
#   OPENVPN_CANAME
#   OPENVPN_DNSNAME
#   PKI_BASE
#
# This script returns the following exit codes:
#   0  - success
#   1  - fail: parameter problem


# required env vars as documented above
export REQ_ENV="\
 OPENVPN_VPNNAME \
 OPENVPN_CANAME \
 OPENVPN_DNSNAME \
 PKI_BASE \
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

### validate user provided input data

# cleanup obscure chars out of passed CA name, for use as file name
THIS_VPN=`echo -n "$OPENVPN_VPNNAME" | tr -cd '[:alnum:]'`

# cleanup obscure chars out of passed CA name, for use as file name
THIS_CA=`echo -n "$OPENVPN_CANAME" | tr -cd '[:alnum:]'`

# cleanup obscure chars out of passed Common Name, for use as file name
THIS_SRV=`echo -n "$OPENVPN_DNSNAME" | tr -cd '[:alnum:].-'`

CERT_SRC=$PKI_BASE/$THIS_CA

mkdir -p $OPENVPN_DIR/$THIS_VPN

# copy ca cert, server key and cert, and DH parameters
install -m 644 \
  $CERT_SRC/ca.crt \
  $CERT_SRC/dh*.pem \
  $CERT_SRC/issued/${THIS_SRV}.crt \
  $OPENVPN_DIR/$THIS_VPN/
install -m 600 \
  $CERT_SRC/private/${THIS_SRV}.key \
  $OPENVPN_DIR/$THIS_VPN/

# copy and modify openvpn config
cp openvpn-samples/server.conf $OPENVPN_DIR/${THIS_VPN}.conf
#sed -e ';' <openvpn-samples/server.conf >$OPENVPN_DIR/${THIS_VPN}.conf

# restart openvpn
#/etc/rc.d/openvpn restart

