#!/bin/sh 

# sign a certificate
#
# The following environment vars need to be passed from the caller:
#   EXISTCA_CAPASS      (eg "craps")
#   EXISTCA_CANAME      (eg "Example CA")
#   EXISTCA_CERTNAME    (eg "John Doe", "existca.example.org")
#   EXISTCA_CERTTYPE    (eg "client", "server")
#   EXISTCA_CERTEXPIRE  (eg 1825)

# sample data for cert request, to be passed from XQuery, hardcoded for now
EXISTCA_CANAME="Example CA"
EXISTCA_CAPASS="craps"
## client (user) cert
EXISTCA_CERTNAME="John Doe"
EXISTCA_CERTTYPE="client"
EXISTCA_CERTEXPIRE=1825
## server cert
#EXISTCA_CERTNAME="www.example.org"
#EXISTCA_CERTTYPE="server"
#EXISTCA_CERTEXPIRE=1825

#FAKE="echo"
#DEBUG=1
if [ -n "$DEBUG" ]; then
    echo -n "cmdline: "
    echo $*
    echo -n "pwd: "
    pwd
    echo "environment:"
    env
    echo "stdin:"
    while read line; do echo $line; done
fi


# XXX validate all user provided input data!

# need $BASEDIR to locate other dirs relative to this
BASEDIR=`pwd`

# source common script vars
. $BASEDIR/ca-scripts/script-vars.sh

err=0

# cleanup obscure chars out of passed CA name, for use as file name
THIS_CA=`echo -n "$EXISTCA_CANAME" | tr -cd '[:alnum:]'`

# strip whitespace (and maybe other) from Common Name, for use as file name
THIS_CN=`echo -n "$EXISTCA_CERTNAME" | tr -cd '[:alnum:].-'`

# pass to easyrsa/openssl as environment vars
export EXISTCA_AUTHIN="env:EXISTCA_CAPASS"
export EXISTCA_AUTHPASS="pass:"
export EXISTCA_CAPASS

# define EASYRSA_PKI to point to $THIS_CA directory
export EASYRSA_PKI=${PKI_BASE}/${THIS_CA}

export EASYRSA_KEY_SIZE=$EXISTCA_CERTKEYSIZE
export EASYRSA_CA_EXPIRE=$EXISTCA_CERTEXPIRE
export EASYRSA_REQ_CN=$EXISTCA_CERTNAME
#export EASYRSA_REQ_COUNTRY="DE"
#export EASYRSA_REQ_PROVINCE="Berlin"
#export EASYRSA_REQ_CITY="Berlin"
#export EASYRSA_REQ_ORG="Example Org"
#export EASYRSA_REQ_OU=""
#export EASYRSA_REQ_EMAIL="jdoe@example.org"

cd $EASYRSA

# sign cert request
$FAKE ./easyrsa sign-req $EXISTCA_CERTTYPE "$THIS_CN"
if [ $? -ne 0 ]; then
    echo "failed to sign $EXISTCA_CERTTYPE certificate"
    err=1
fi

# export to PKCS#12 format
$FAKE ./easyrsa export-p12 "$THIS_CN"
if [ $? -ne 0 ]; then
    echo "failed to export certificate to PKCS#12 format"
    err=1
fi


if [ $err -ne 0 ]; then
    echo "ERROR signing $EXISTCA_CERTTYPE certificate request"
    exit 1
else
    exit 0
fi

