#!/bin/sh 

# revoke a certificate
#
# The following environment vars need to be passed from the caller:
#   EXISTCA_CAPASS      (eg "craps")
#   EXISTCA_CANAME      (eg "Example CA")
#   EXISTCA_CERTNAME    (eg "John Doe", "existca.example.org")
#   EXISTCA_HOME          (eg /usr/local/eXistCA)
#   EXISTCA XMLOUT
#   PKI_BASE
#
# This script returns the following exit codes:
#   0  - success
#   1  - fail: parameter problem
#   2  - fail: 

# required env vars as documented above
export REQ_ENV="\
 EXISTCA_CAPASS \
 EXISTCA_CANAME \
 EXISTCA_CERTNAME \
 EXISTCA_HOME \
 EXISTCA_XMLOUT \
 PKI_BASE \
"

#FAKE="echo"

# dump cert data as XML
dump_xml () {
#    printf "<XXX/>"
}

# source common script vars
. $EXISTCA_HOME/script-vars.sh

err=0

# env sanity checks
if ! checkenv $REQ_ENV; then
    echo "ERROR - refuse to work on incomplete data"
    err=1
fi

### nothing to validate

# cleanup obscure chars out of passed CA name, for use as file name
THIS_CA=`echo "$EXISTCA_CANAME" | tr -cd '[:alnum:]'`

# cleanup obscure chars out of passed Common Name, for use as file name
THIS_CN=`echo "$EXISTCA_CERTNAME" | tr -cd '[:alnum:].-'`

# err out with exit code 1 (parameter problem)
if [ $err -ne 0 ]; then
    logmsg "ERROR \"$THIS_CA\" - revoking $EXISTCA_CERTTYPE certificate: parameter problem"
#    printf "<XXX/>"
    exit 1
fi


### setup env for easyrsa

# define EASYRSA_PKI to point to $THIS_CA directory
export EASYRSA_PKI=${PKI_BASE}/${THIS_CA}

cd $EASYRSA

EXISTCA_AUTHIN="env:EXISTCA_CAPASS"
EXISTCA_AUTHOUT=
export EXISTCA_AUTHIN EXISTCA_AUTHOUT EXISTCA_AUTHPASS EXISTCA_CAPASS

# revoke cert
$FAKE ./easyrsa revoke "$THIS_CN"
if [ $? -ne 0 ]; then
    logmsg "ERROR \"$THIS_CA\" - revoking $CERTTYPE certificate"
    err=1
fi

# generate new crl
$FAKE ./easyrsa gen-crl
if [ $? -ne 0 ]; then
    logmsg "ERROR \"$THIS_CA\" - creating certificate revocation list"
    err=1
fi


# dump XML data to stdout regardless of possible errors
dump_xml

# err out with exit code 2
if [ $err -ne 0 ]; then
    logmsg "ERROR \"$THIS_CA\" - revoking $EXISTCA_CERTTYPE certificate"
    exit 2
fi


exit 0
