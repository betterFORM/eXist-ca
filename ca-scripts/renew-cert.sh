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
#   EXISTCA_HOME        (eg /usr/local/eXistCA)
#   EXISTCA XMLOUT
#   PKI_BASE
#
# This script returns the following exit codes:
#   0  - success
#   1  - fail: parameter problem
#   2  - fail: 

[ -n "$DEBUG" ] && set -x

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

# dump cert data as XML
dump_xml () {
}

# source common script vars
. $EXISTCA_HOME/script-vars.sh

err=0

# env sanity checks
if ! checkenv $REQ_ENV; then
    logmsg "ERROR - refuse to work on incomplete data"
    err=1
fi

### validate all user provided input data

# cleanup obscure chars out of passed CA name, for use as file name
THIS_CA=`echo "$EXISTCA_CANAME" | tr -cd '[:alnum:]'`

# cleanup obscure chars out of passed Common Name, for use as file name
THIS_CN=`echo "$EXISTCA_CERTNAME" | tr -cd '[:alnum:].-'`


### setup env for easyrsa

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
    logmsg "ERROR \"$THIS_CA\" - revoking $EXISTCA_CERTTYPE certificate"
    err=1
fi

# sign cert request
EXISTCA_AUTHIN="env:EXISTCA_CAPASS"
EXISTCA_AUTHOUT=
$FAKE ./easyrsa sign-req $EXISTCA_CERTTYPE "$THIS_CN"
if [ $? -ne 0 ]; then
    logmsg "ERROR \"$THIS_CA\" - failed to sign $EXISTCA_CERTTYPE certificate"
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
    logmsg "ERROR \"$THIS_CA\" - failed to export certificate to PKCS#12 format"
    err=1
fi

# generate new crl
EXISTCA_AUTHIN="env:EXISTCA_CAPASS"
$FAKE ./easyrsa gen-crl
if [ $? -ne 0 ]; then
    logmsg "ERROR \"$THIS_CA\" - creating certificate revocation list"
    err=1
fi


# dump XML data to stdout regardless of possible errors
dump_xml

# err out with exit code 2
if [ $err -ne 0 ]; then
    logmsg "ERROR \"$THIS_CA\" - renewing $EXISTCA_CERTTYPE certificate"
    exit 2
fi


exit 0
