#!/bin/sh 

# request a certificate
#
# The following environment vars need to be passed from the caller:
#   EXISTCA_CANAME      (eg "Example CA")
#   EXISTCA_CERTNAME    (eg "John Doe", "existca.example.org")
#   EXISTCA_CERTPASS    (eg "test")
#   EXISTCA_CERTTYPE    (eg "client", "server")
#   EXISTCA_CERTKEYSIZE (eg 2048)

# required env vars as documented above
export REQ_ENV="\
 EXISTCA_CANAME \
 EXISTCA_CERTNAME \
 EXISTCA_CERTPASS \
 EXISTCA_CERTTYPE \
 EXISTCA_CERTKEYSIZE \
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

export EASYRSA_KEY_SIZE=$EXISTCA_CERTKEYSIZE
export EASYRSA_CA_EXPIRE=$EXISTCA_CERTEXPIRE
export EASYRSA_REQ_CN=$EXISTCA_CERTNAME
#export EASYRSA_REQ_COUNTRY="DE"
#export EASYRSA_REQ_PROVINCE="Berlin"
#export EASYRSA_REQ_CITY="Berlin"
#export EASYRSA_REQ_ORG="Example Org"
#export EASYRSA_REQ_OU=""
#export EASYRSA_REQ_EMAIL="jdoe@example.org"

EXISTCA_AUTHIN=
EXISTCA_AUTHOUT=
EXISTCA_AUTHPASS=
export EXISTCA_AUTHIN EXISTCA_AUTHOUT EXISTCA_AUTHPASS EXISTCA_CERTPASS

cd $EASYRSA

# create cert request
EXISTCA_AUTHOUT="env:EXISTCA_CERTPASS"
$FAKE ./easyrsa gen-req "$THIS_CN" nopass
if [ $? -ne 0 ]; then
    echo "failed to generate certificate request"
    err=1
fi


if [ $err -ne 0 ]; then
    echo "ERROR creating $EXISTCA_CERTTYPE certificate request"
    exit 1
else
    exit 0
fi

