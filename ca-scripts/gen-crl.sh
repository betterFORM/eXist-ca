#!/bin/sh 

# create a certificate revocation list
#
# The following environment vars need to be passed from the caller:
#   EXISTCA_CAPASS      (eg "craps")
#   EXISTCA_CANAME      (eg "Example CA")

# required env vars as documented above
REQ_ENV="\
 EXISTCA_CAPASS \
 EXISTCA_CANAME \
 EXISTCA_HOME \
 PKI_BASE \
"

#FAKE="echo"
#DEBUG=1
if [ -n "$DEBUG" ]; then
    echo "cmdline: "
    echo $*
    echo "pwd: "
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
THIS_CA=`echo "$EXISTCA_CANAME" | tr -cd '[:alnum:]'`

# define EASYRSA_PKI to point to $THIS_CA directory
export EASYRSA_PKI=${PKI_BASE}/${THIS_CA}

cd $EASYRSA

# create crl
EXISTCA_AUTHIN="env:EXISTCA_CAPASS"
export EXISTCA_AUTHIN EXISTCA_CAPASS
$FAKE ./easyrsa gen-crl
if [ $? -ne 0 ]; then
    echo "ERROR creating certificate revocation list"
    exit 1
fi

exit 0

