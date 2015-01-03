#!/bin/sh 

# sign a certificate
#
# The following environment vars need to be passed from the caller:
#   EXISTCA_CAPASS      (eg "craps")
#   EXISTCA_CANAME      (eg "Example CA")
#   EXISTCA_CERTNAME    (eg "John Doe", "existca.example.org")
#   EXISTCA_CERTTYPE    (eg "client", "server")
#   EXISTCA_CERTEXPIRE  (eg 1825)
#   EXISTCA_CERTPASS
#   EXISTCA HOME
#   PKI_BASE
#
# This script returns the following exit codes:
#   0  - success
#   1  - fail: parameter problem
#   2  - fail: sign cert

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
    cert_crt=`cat $EASYRSA_PKI/issued/${THIS_CN}.crt`
    #cert_pkcs12=`cat $EASYRSA_PKI/private/${THIS_CN}.p12`
    cert_pkcs12='this is binary and needs encoding'
    cert_text=`sh ./easyrsa show-cert "$THIS_CN"`
    read status expire serial unkn cn <<INDEX
$(grep "$THIS_CN" $EASYRSA_PKI/index.txt)
INDEX
    exp_date=`openssl x509 -text -in $EASYRSA_PKI/issued/${THIS_CN}.crt | grep "Not After" | sed 's/.*Not After : //;'`
    # note this return only XML elements that must be updated
    printf "
<cert name=\"$THIS_CN\" nicename=\"$EXISTCA_CERTNAME\">
  <certtype>$EXISTCA_CERTTYPE</certtype>
  <expire>$EXISTCA_CERTEXPIRE</expire>
  <status>$status</status>
  <expire-timestamp>$expire</expire-timestamp>
  <serial>$serial</serial>
  <expiry-date>$exp_date</expiry-date>
  <cert>$cert_crt</cert>
  <pkcs12>$cert_pkcs12</pkcs12>
  <cert-textual>$cert_text</cert-textual>
</cert>
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

### validate all user provided input data

# cleanup obscure chars out of passed CA name, for use as file name
THIS_CA=`echo "$EXISTCA_CANAME" | tr -cd '[:alnum:]'`

# cleanup obscure chars out of passed Common Name, for use as file name
THIS_CN=`echo "$EXISTCA_CERTNAME" | tr -cd '[:alnum:].-'`

# verify expire value is postive integer
if ! verify_posint $EXISTCA_CERTEXPIRE; then
    logmsg "ERROR \"$THIS_CA\" - invalid $EXISTCA_CERTEXPIRE data"
    err=1
fi
# verify cert type input data
if ! verify_certtype $EXISTCA_CERTTYPE; then
    logmsg "ERROR \"$THIS_CA\" - invalid $EXISTCA_CERTTYPE data"
    err=1
fi

# err out with exit code 1 (parameter problem)
if [ $err -ne 0 ]; then
    logmsg "ERROR \"$THIS_CA\" - creating $EXISTCA_CERTTYPE cert: parameter problem"
    printf "<cert/>"
    exit 1
fi


### setup env for easyrsa

# define EASYRSA_PKI to point to $THIS_CA directory
export EASYRSA_PKI=${PKI_BASE}/${THIS_CA}

export EASYRSA_CERT_EXPIRE=$EXISTCA_CERTEXPIRE
export EASYRSA_REQ_CN=$THIS_CN

EXISTCA_AUTHIN=
EXISTCA_AUTHOUT=
EXISTCA_AUTHPASS=
export EXISTCA_AUTHIN EXISTCA_AUTHOUT EXISTCA_AUTHPASS
export EXISTCA_CAPASS EXISTCA_CERTPASS EXISTCA_EXPORTPASS

cd $EASYRSA

# sign cert request
EXISTCA_AUTHIN="env:EXISTCA_CAPASS"
EXISTCA_AUTHOUT=
$FAKE ./easyrsa sign-req "$EXISTCA_CERTTYPE" "$THIS_CN"
if [ $? -ne 0 ]; then
    logmsg "ERROR \"$THIS_CA\" - failed to sign $EXISTCA_CERTTYPE certificate"
    err=1
fi

# export to PKCS#12 format
if [ -n "$EXISTCA_CERTPASS" ]; then
    EXISTCA_AUTHIN="env:EXISTCA_CERTPASS"
    #EXISTCA_AUTHPASS="env:EXISTCA_CERTPASS"
    EXISTCA_AUTHPASS="env:EXISTCA_EXPORTPASS"
else
    EXISTCA_AUTHIN=
    EXISTCA_AUTHPASS="env:EXISTCA_EXPORTPASS"
fi
$FAKE ./easyrsa export-p12 "$THIS_CN"
if [ $? -ne 0 ]; then
    logmsg "ERROR \"$THIS_CA\" - failed to export certificate to PKCS#12 format"
    err=1
fi


# dump XML data to stdout regardless of possible errors
dump_xml

# err out with exit code 2 (sign cert)
if [ $err -ne 0 ]; then
    logmsg "ERROR \"$THIS_CA\" - signing $EXISTCA_CERTTYPE certificate request"
    exit 2
fi


exit 0
