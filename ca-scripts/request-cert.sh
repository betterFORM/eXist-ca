#!/bin/sh 

# request a certificate
#
# The following environment vars need to be passed from the caller:
#   EXISTCA_CANAME        (eg "Example CA")
#   EXISTCA_CERTNAME      (eg "John Doe", "existca.example.org")
#   EXISTCA_CERTPASS      (eg "test")
#   EXISTCA_CERTTYPE      (eg "client", "server")
#   EXISTCA_CERTKEYSIZE   (eg 2048)
#   EXISTCA_CERTCOUNTRY   (eg "DE")
#   EXISTCA_CERTPROVINCE  (eg "Berlin")
#   EXISTCA_CERTCITY      (eg "Berlin")
#   EXISTCA_CERTORG       (eg "Example Org")
#   EXISTCA_CERTOU        (eg "CA")
#   EXISTCA_CERTEMAIL     (eg "ca@example.org")
#   EXISTCA_HOME          (eg /usr/local/eXistCA)
#   EXISTCA XMLOUT
#   PKI_BASE
#
# This script returns the following exit codes:
#   0  - success
#   1  - fail: parameter problem
#   2  - fail: cert request creation

# required env vars as documented above
export REQ_ENV="\
 EXISTCA_CANAME \
 EXISTCA_CERTNAME \
 EXISTCA_CERTPASS \
 EXISTCA_CERTTYPE \
 EXISTCA_CERTKEYSIZE \
 EXISTCA_CERTCOUNTRY \
 EXISTCA_CERTPROVINCE \
 EXISTCA_CERTCITY \
 EXISTCA_CERTORG \
 EXISTCA_CERTOU \
 EXISTCA_CERTEMAIL \
 EXISTCA_HOME \
 EXISTCA_XMLOUT \
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

# dump server data as XML
#dump_xml () {
#    printf "
#<cert>
#</cert>
#" >$EXISTCA_XMLOUT
#}

# source common script vars
. $EXISTCA_HOME/script-vars.sh

err=0

# env sanity checks
if ! checkenv $REQ_ENV; then
    logmsg "ERROR - refuse to work on incomplete data"
    err=1
fi

### validate user provided input data

# verify keysize user input
if ! verify_rsakeysize $EXISTCA_CERTKEYSIZE; then
    logmsg "ERROR - key size $EXISTCA_CERTKEYSIZE not supported"
    err=1
fi

# cleanup obscure chars out of passed CA name, for use as file name
THIS_CA=`echo -n "$EXISTCA_CANAME" | tr -cd '[:alnum:]'`

# cleanup obscure chars out of passed Common Name, for use as file name
THIS_CN=`echo -n "$EXISTCA_CERTNAME" | tr -cd '[:alnum:].-'`

# err out with exit code 1 (parameter problem)
if [ $err -ne 0 ]; then
    logmsg "ERROR creating cert request: parameter problem"
    printf "<cert/>"
    exit 1
fi


### setup env for easyrsa

# define EASYRSA_PKI to point to $THIS_CA directory
export EASYRSA_PKI=${PKI_BASE}/${THIS_CA}

export EASYRSA_KEY_SIZE=$EXISTCA_CERTKEYSIZE
export EASYRSA_CERT_EXPIRE=$EXISTCA_CERTEXPIRE
export EASYRSA_REQ_CN=$EXISTCA_CERTNAME
export EASYRSA_REQ_COUNTRY=$EXISTCA_CERTCOUNTRY
export EASYRSA_REQ_PROVINCE=$EXISTCA_CERTPROVINCE
export EASYRSA_REQ_CITY=$EXISTCA_CERTCITY
export EASYRSA_REQ_ORG=$EXISTCA_CERTORG
export EASYRSA_REQ_OU=$EXISTCA_CERTOU
export EASYRSA_REQ_EMAIL=$EXISTCA_CERTEMAIL

# reset and export auth related vars
EXISTCA_AUTHIN=
EXISTCA_AUTHOUT=
EXISTCA_AUTHPASS=
export EXISTCA_AUTHIN EXISTCA_AUTHOUT EXISTCA_AUTHPASS
export EXISTCA_CAPASS EXISTCA_CERTPASS EXISTCA_EXPORTPASS

cd $EASYRSA

# create cert request
if [ -n "$EXISTCA_CERTPASS" ]; then
    EXISTCA_AUTHOUT="env:EXISTCA_CERTPASS"
else
    EXISTCA_AUTHOUT=
    genreq_opt=nopass
fi
EXISTCA_AUTHIN=
$FAKE sh ./easyrsa gen-req "$THIS_CN" $genreq_opt
if [ $? -ne 0 ]; then
    logmsg "ERROR \"$THIS_CA\" - failed to generate certificate request"
    err=1
fi


# dump XML data to stdout regardless of possible errors
#dump_xml

# err out with exit code 3 (server cert)
if [ $err -ne 0 ]; then
    logmsg "ERROR \"$THIS_CA\" - failed to create $EXISTCA_CERTTYPE certificate request"
    exit 2
fi


exit 0
