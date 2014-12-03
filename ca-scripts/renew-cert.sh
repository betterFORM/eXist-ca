#!/bin/sh 

# renew a certificate
#
# The following environment vars need to be passed from the caller:
#   EXISTCA_CAPASS      (eg "craps")
#   EXISTCA_CANAME      (eg "Example CA")
#   EXISTCA_CERTNAME    (eg "John Doe", "existca.example.org")
#   EXISTCA_CERTTYPE    (eg "client", "server")
#   EXISTCA_CERTEXPIRE  (eg 1825)
#   EXISTCA_CERTPASS    (eg "secret")

# required env vars as documented above
REQ_ENV="\
 EXISTCA_CAPASS \
 EXISTCA_CANAME \
 EXISTCA_CERTNAME \
 EXISTCA_CERTTYPE \
 EXISTCA_CERTEXPIRE \
 EXISTCA_CERTPASS \
 EXISTCA_HOME \
 PKI_BASE \
"

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


# source common script vars
. $EXISTCA_HOME/script-vars.sh

# env sanity checks
if ! checkenv $REQ_ENV; then
    echo "ERROR - refuse to work on incomplete data"
    exit 1
fi

# XXX validate all user provided input data!

err=0

# cleanup obscure chars out of passed CA name, for use as file name
THIS_CA=`echo -n "$EXISTCA_CANAME" | tr -cd '[:alnum:]'`

# cleanup obscure chars out of passed Common Name, for use as file name
THIS_CN=`echo -n "$EXISTCA_CERTNAME" | tr -cd '[:alnum:].-'`

# define EASYRSA_PKI to point to $THIS_CA directory
export EASYRSA_PKI=${PKI_BASE}/${THIS_CA}

export EASYRSA_CA_EXPIRE=$EXISTCA_CERTEXPIRE
export EASYRSA_REQ_CN=$EXISTCA_CERTNAME

EXISTCA_AUTHIN=
EXISTCA_AUTHOUT=
EXISTCA_AUTHPASS=
export EXISTCA_AUTHIN EXISTCA_AUTHOUT EXISTCA_AUTHPASS
export EXISTCA_CAPASS EXISTCA_CERTPASS EXISTCA_EXPORTPASS

cd $EASYRSA

# revoke cert
EXISTCA_AUTHIN="env:EXISTCA_CAPASS"
EXISTCA_AUTHOUT=
$FAKE ./easyrsa revoke "$THIS_CN"
if [ $? -ne 0 ]; then
    echo "ERROR revoking $EXISTCA_CERTTYPE certificate"
    err=1
fi

# sign cert request
EXISTCA_AUTHIN="env:EXISTCA_CAPASS"
EXISTCA_AUTHOUT=
$FAKE ./easyrsa sign-req $EXISTCA_CERTTYPE "$THIS_CN"
if [ $? -ne 0 ]; then
    echo "failed to sign $EXISTCA_CERTTYPE certificate"
    err=1
fi

# export to PKCS#12 format
if [ -n "$EXISTCA_CERTPASS" ]; then
    EXISTCA_AUTHIN="env:EXISTCA_CERTPASS"
    EXISTCA_AUTHPASS="env:EXISTCA_CERTPASS"
else
    EXISTCA_AUTHIN=
    EXISTCA_AUTHPASS="env:EXISTCA_EXPORTPASS"
fi
$FAKE ./easyrsa export-p12 "$THIS_CN"
if [ $? -ne 0 ]; then
    echo "failed to export certificate to PKCS#12 format"
    err=1
fi

# generate new crl
EXISTCA_AUTHIN="env:EXISTCA_CAPASS"
$FAKE ./easyrsa gen-crl
if [ $? -ne 0 ]; then
    echo "ERROR creating certificate revocation list"
    err=1
fi


if [ $err -ne 0 ]; then
    echo "ERROR renewing $EXISTCA_CERTTYPE certificate"
    exit 1
else
    exit 0
fi

