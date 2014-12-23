#!/bin/sh 

# create a certiificate in one go (req,sign,pkcs12)
#
# The following environment vars need to be passed from the caller 
# (vars may have no value, but must be present in the environment):
#   EXISTCA_CAPASS        (eg "craps")
#   EXISTCA_CANAME        (eg "Example CA")
#   EXISTCA_CERTNAME      (eg "John Doe", "existca.example.org")
#   EXISTCA_CERTPASS      (eg "test")
#   EXISTCA_CERTTYPE      (eg "client", "server")
#   EXISTCA_CERTKEYSIZE   (eg 2048)
#   EXISTCA_CERTEXPITE    (eg 1825)
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
#   2  - fail: cert creation


# required env vars as documented above
REQ_ENV="\
 EXISTCA_CAPASS \
 EXISTCA_CANAME \
 EXISTCA_CERTNAME \
 EXISTCA_CERTPASS \
 EXISTCA_CERTTYPE \
 EXISTCA_CERTKEYSIZE \
 EXISTCA_CERTEXPIRE \
 EXISTCA_CERTCOUNTRY \
 EXISTCA_CERTPROVINCE \
 EXISTCA_CERTCITY \
 EXISTCA_CERTORG \
 EXISTCA_CERTOU \
 EXISTCA_CERTEMAIL \
 EXISTCA_HOME \
 EXISTCA_EXPORTPASS \
 EXISTCA_XMLOUT \
 PKI_BASE \
"

#FAKE="echo"

# dump cert data as XML
dump_xml () {
    cert_crt=`cat $EASYRSA_PKI/issued/${THIS_CN}.crt`
    cert_key=`cat $EASYRSA_PKI/private/${THIS_CN}.key`
    #cert_pkcs12=`cat $EASYRSA_PKI/private/${THIS_CN}.p12`
    cert_pkcs12='this is binary and needs encoding'
    cert_req=`cat $EASYRSA_PKI/reqs/${THIS_CN}.req`
    cert_text=`sh ./easyrsa show-cert "$THIS_CN"`
    req_text=`sh ./easyrsa show-req "$THIS_CN"`
    read status expire serial unkn cn <<INDEX
$(grep "$THIS_CN" $EASYRSA_PKI/index.txt)
INDEX
    exp_date=`openssl x509 -text -in $EASYRSA_PKI/issued/${THIS_CN}.crt | grep "Not After" | sed 's/.*Not After : //;'`
    printf "
<cert name=\"$THIS_CN\" nicename=\"$EXISTCA_CERTNAME\">
  <certtype>$EXISTCA_CERTTYPE</certtype>
  <keysize>$EXISTCA_CERTKEYSIZE</keysize>
  <expire>$EXISTCA_CERTEXPIRE</expire>
  <status>$status</status>
  <expire-timestamp>$expire</expire-timestamp>
  <serial>$serial</serial>
  <expiry-date>$exp_date</expiry-date>
  <certpass>$EXISTCA_CERTPASS</certpass>
  <country>$EXISTCA_CERTCOUNTRY</country>
  <province>$EXISTCA_CERTPROVINCE</province>
  <city>$EXISTCA_CERTCITY</city>
  <org>$EXISTCA_CERTORG</org>
  <org-unit>$EXISTCA_CERTOU</org-unit>
  <email>$EXISTCA_CERTEMAIL</email>
  <cert>$cert_crt</cert>
  <key>$cert_key</key>
  <pkcs12>$cert_pkcs12</pkcs12>
  <req>$cert_req</req>
  <cert-textual>$cert_text</cert-textual>
  <req-textual>$req_text</req-textual>
</cert>
" >$EXISTCA_XMLOUT
}

# source common script vars
. $EXISTCA_HOME/script-vars.sh

err=0

# env sanity checks
if ! checkenv $REQ_ENV; then
    logmsg "ERROR - refuse to work on incomplete data"
    err=1
fi

### validate user provided input data

# cleanup obscure chars out of passed CA name, for use as file name
THIS_CA=`echo "$EXISTCA_CANAME" | tr -cd '[:alnum:]'`

# cleanup obscure chars out of passed Common Name, for use as file name
THIS_CN=`echo "$EXISTCA_CERTNAME" | tr -cd '[:alnum:].-'`

# verify keysize user input
if ! verify_rsakeysize $EXISTCA_CERTKEYSIZE; then
    logmsg "ERROR \"$THIS_CA\" - key size $EXISTCA_CERTKEYSIZE not supported"
    err=1
fi
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
    logmsg "ERROR \"$THIS_CA\" - creating $EXISTCA_CERTTYPE certificate: parameter problem"
    printf "<cert/>"
    exit 1
fi


### setup env for easyrsa

# define EASYRSA_PKI to point to $THIS_CA directory
export EASYRSA_PKI=${PKI_BASE}/${THIS_CA}

export EASYRSA_KEY_SIZE=$EXISTCA_CERTKEYSIZE
export EASYRSA_CERT_EXPIRE=$EXISTCA_CERTEXPIRE
export EASYRSA_REQ_CN=$THIS_CN
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

# sign cert request
EXISTCA_AUTHIN="env:EXISTCA_CAPASS"
EXISTCA_AUTHOUT=
$FAKE sh ./easyrsa sign-req "$EXISTCA_CERTTYPE" "$EASYRSA_REQ_CN"
if [ $? -ne 0 ]; then
    logmsg "ERROR \"$THIS_CA\" - failed to sign $EXISTCA_CERTTYPE certificate"
    err=1
fi

# build PKCS12 cert data structure
if [ -n "$EXISTCA_CERTPASS" ]; then
    EXISTCA_AUTHIN="env:EXISTCA_CERTPASS"
    #EXISTCA_AUTHPASS="env:EXISTCA_CERTPASS"
    EXISTCA_AUTHPASS="env:EXISTCA_EXPORTPASS"
else
    EXISTCA_AUTHIN=
    EXISTCA_AUTHPASS="env:EXISTCA_EXPORTPASS"
fi
$FAKE sh ./easyrsa export-p12 "$EASYRSA_REQ_CN"
if [ $? -ne 0 ]; then
    logmsg "ERROR \"$THIS_CA\" - failed to pkcs12 export $EXISTCA_CERTTYPE certificate"
    err=1
fi


# dump XML data to stdout regardless of possible errors
dump_xml

# err out with exit code 2
if [ $err -ne 0 ]; then
    logmsg "ERROR \"$THIS_CA\" - failed to create $EXISTCA_CERTTYPE certificate"
    exit 2
fi


exit 0
