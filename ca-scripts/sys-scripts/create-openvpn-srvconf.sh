#!/bin/sh

# modify OpenVPN configuration
#
# The following environment vars need to be passed from the caller 
# (vars may have no value, but must be present in the environment):
#   OPENVPN_VPNNAME
#   OPENVPN_VPNNUM
#   OPENVPN_SRVADDR
#   OPENVPN_SRVPORT
#   OPENVPN_SRVPROTO
#   OPENVPN_NETWORK
#   OPENVPN_NETMASK
#   OPENVPN_CANAME
#   OPENVPN_CIPHER
#   OPENVPN_DNSNAME
#   PKI_BASE
#   APPLIANCE_HOME
#
# This script returns the following exit codes:
#   0  - success
#   1  - fail: parameter problem
#   2  - fail: OpenVPN config

[ -n "$DEBUG" ] && set -x

# required env vars as documented above
export REQ_ENV="\
 OPENVPN_VPNNAME \
 OPENVPN_VPNNUM \
 OPENVPN_SRVADDR \
 OPENVPN_SRVPORT \
 OPENVPN_SRVPROTO \
 OPENVPN_NETWORK \
 OPENVPN_NETMASK \
 OPENVPN_CANAME \
 OPENVPN_CIPHER \
 OPENVPN_DNSNAME \
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
THIS_CA=`echo "$OPENVPN_CANAME" | tr -cd '[:alnum:]'`

# cleanup obscure chars out of passed Common Name, for use as file name
THIS_SRV=`echo "$OPENVPN_DNSNAME" | tr -cd '[:alnum:].-'`

# verify server address value is an IP address
if ! verify_ipaddr $OPENVPN_SRVADDR; then
    logmsg "ERROR \"$THIS_VPN\" - invalid server address $OPENVPN_SRVADDR"
    err=1
fi
# verify port number value is postive integer
if ! verify_posint $OPENVPN_SRVPORT; then
    logmsg "ERROR \"$THIS_VPN\" - invalid port $OPENVPN_SRVPORT"
    err=1
fi
# verify protocol value
if [ "$OPENVPN_SRVPROTO" != udp -a "$OPENVPN_SRVPROTO" != tcp ]; then
    logmsg "ERROR \"$THIS_VPN\" - invalid protocol $OPENVPN_SRVPROTO"
    err=1
fi
# verify network and netmask values are IP addresses
if ! verify_ipaddr $OPENVPN_NETWORK; then
    logmsg "ERROR \"$THIS_VPN\" - invalid network address $OPENVPN_NETWORK"
    err=1
fi
if ! verify_ipaddr $OPENVPN_NETMASK; then
    logmsg "ERROR \"$THIS_VPN\" - invalid netmask $OPENVPN_NETMASK"
    err=1
fi
# verify cipher value
case "$OPENVPN_CIPHER" in
    "AES-256-CBC"|"BF-CBC") : ;;
    *) 
	logmsg "ERROR \"$THIS_VPN\" - invalid cipher $OPENVPN_CIPHER"
	err=1
	;;
esac

if [ -f $OPENVPN_DIR/${THIS_VPN}.conf ]; then
    logmsg "refusing to overwrite existing VPN config file $OPENVPN_DIR/${THIS_VPN}.conf"
    err=1
fi
if [ -d $OPENVPN_DIR/${THIS_VPN} ]; then
    logmsg "refusing to overwrite existing VPN config dir $OPENVPN_DIR/${THIS_VPN}"
    err=1
fi

# err out with exit code 1 (parameter problem)
if [ $err -ne 0 ]; then
    logmsg "ERROR \"$THIS_VPN\" - creating VPN config: parameter problem"
    exit 1
fi


CERT_SRC=$PKI_BASE/$THIS_CA

mkdir -p $OPENVPN_DIR/$THIS_VPN

# copy ca cert, server key and cert, and DH parameters
install -m 644 \
  $CERT_SRC/ca.crt \
  $CERT_SRC/dh4096.pem \
  $CERT_SRC/issued/${THIS_SRV}.crt \
  $OPENVPN_DIR/$THIS_VPN/ || err=1
install -m 600 \
  $CERT_SRC/private/${THIS_SRV}.key \
  $OPENVPN_DIR/$THIS_VPN/ || err=1
[ -f $CERT_SRC/crl.pem ] && install -m 644 \
  $CERT_SRC/crl.pem \
  $OPENVPN_DIR/$THIS_VPN/ || err=1

# generate HMAC key for DoS protection
openvpn --genkey --secret $OPENVPN_DIR/$THIS_VPN/ta.key || err=1

# copy and modify openvpn config
#cp openvpn-samples/server.conf $OPENVPN_DIR/${THIS_VPN}.conf
sed -e "\
 s|INSTANCE|${THIS_VPN}|;\
 s|dev DEVICE|dev tun${OPENVPN_VPNNUM}|;\
 s|local SRVADDR|local ${OPENVPN_SRVADDR}|;\
 s|port SRVPORT|port ${OPENVPN_SRVPORT}|;\
 s|proto SRVPROTO|proto ${OPENVPN_SRVPROTO}|;\
 s|server NETWORK NETMASK|server ${OPENVPN_NETWORK} ${OPENVPN_NETMASK}|;\
 s|ca CACERT|ca ${OPENVPN_DIR}/${THIS_VPN}/ca.crt|;\
 s|cert SRVCERT|cert ${OPENVPN_DIR}/${THIS_VPN}/${THIS_SRV}.crt|;\
 s|key SRVKEY|key ${OPENVPN_DIR}/${THIS_VPN}/${THIS_SRV}.key|;\
 s|dh DH|dh ${OPENVPN_DIR}/${THIS_VPN}/dh4096.pem|;\
 s|crl-verify CACRL|crl-verify ${OPENVPN_DIR}/${THIS_VPN}/crl.pem|;\
 s|tls-auth ta.key|tls-auth ${OPENVPN_DIR}/${THIS_VPN}/ta.key|;\
 s|cipher CIPHER|cipher ${OPENVPN_CIPHER}|;\
 s|user USER|user ${OPENVPN_USER}|;\
 s|group GROUP|group ${OPENVPN_GROUP}|;\
 s|chroot CHROOT|chroot ${OPENVPN_CHROOT}|;" \
    <$APPLIANCE_HOME/openvpn-samples/server.conf \
    >$OPENVPN_DIR/${THIS_VPN}.conf || err=1

# example client config file for this VPN
#cp openvpn-samples/client.conf $OPENVPN_DIR/${THIS_VPN}-client.ovpn
sed -e "\
 s|dev-node INSTANCE|dev-node ${THIS_VPN}|;\
 s|remote SRVADDR SRVPORT|remote ${OPENVPN_SRVADDR} ${OPENVPN_SRVPORT}|;\
 s|proto SRVPROTO|proto ${OPENVPN_SRVPROTO}|;\
 s|pkcs12 SRVP12|key CLIENT.p12|;\
 s|tls-auth ta.key|tls-auth ta.key|;\
 s|cipher CIPHER|cipher ${OPENVPN_CIPHER}|;" \
    <$APPLIANCE_HOME/openvpn-samples/client.conf \
    >$OPENVPN_DIR/${THIS_VPN}/client.ovpn || err=1

# err out with exit code 2 (OpenVPN config)
if [ $err -ne 0 ]; then
    logmsg "ERROR \"$THIS_VPN\" - failed to create VPN config"
    exit 2
fi

# restart openvpn
#/etc/rc.d/openvpn restart

