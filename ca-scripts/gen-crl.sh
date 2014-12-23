#!/bin/sh 

# create a certificate revocation list
#
# The following environment vars need to be passed from the caller:
#   EXISTCA_CAPASS      (eg "craps")
#   EXISTCA_CANAME      (eg "Example CA")
#   EXISTCA_HOME        (eg /usr/local/eXistCA)
#   EXISTCA XMLOUT
#   PKI_BASE
#
# This script returns the following exit codes:
#   0  - success
#   1  - fail: parameter problem
#   2  - fail: CRL generation


# required env vars as documented above
REQ_ENV="\
 EXISTCA_CAPASS \
 EXISTCA_CANAME \
 EXISTCA_HOME \
 EXISTCA_XMLOUT \
 PKI_BASE \
"

#FAKE="echo"

# dump CA and server data as XML
dump_xml () {
    printf "
<crl/>
" >$EXISTCA_XMLOUT
}

# source common script vars
. $EXISTCA_HOME/script-vars.sh

err=0

# env sanity checks
if ! checkenv $REQ_ENV; then
    echo "ERROR - refuse to work on incomplete data"
    err=1
fi

### validate user provided input data

# cleanup obscure chars out of passed CA name, for use as file name
THIS_CA=`echo "$EXISTCA_CANAME" | tr -cd '[:alnum:]'`

# err out with exit code 1 (parameter problem)
if [ $err -ne 0 ]; then
    logmsg "ERROR \"$THIS_CA\" - generating CRL: parameter problem"
    printf "<crl/>"
    exit 1
fi


### setup env for easyrsa

# define EASYRSA_PKI to point to $THIS_CA directory
export EASYRSA_PKI=${PKI_BASE}/${THIS_CA}

# reset and export auth related vars
EXISTCA_AUTHIN="env:EXISTCA_CAPASS"
EXISTCA_AUTHOUT=
export EXISTCA_AUTHIN EXISTCA_AUTHOUT EXISTCA_CAPASS

cd $EASYRSA

# create crl
$FAKE ./easyrsa gen-crl
if [ $? -ne 0 ]; then
    logmsg "ERROR creating certificate revocation list"
    printf "<CA/>"
    exit 2
fi

# dump XML data to stdout regardless of possible errors (some XML fields 
# may be left blank if server cert failed)
dump_xml


exit 0

