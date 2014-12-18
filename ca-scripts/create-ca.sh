#!/bin/sh 

# create a CA instance, including these steps
# . init CA infrastructure
# . create CA key and cert
# . create SSL server cert for eXist web frontend
# . install SSL server cert into eXist jetty and prepare for reload
# . fixup network setup if required
#
# The following environment vars need to be passed from the caller 
# (vars may have no value, but must be present in the environment):
#   EXISTCA_CAPASS      (eg "craps")
#   EXISTCA_CANAME      (eg "Example CA")
#   EXISTCA_CAKEYSIZE   (eg 4096)
#   EXISTCA_CAEXPIRE    (eg 3650)
#   EXISTCA_CACOUNTRY   (eg "DE")
#   EXISTCA_CAPROVINCE  (eg "Berlin")
#   EXISTCA_CACITY      (eg "Berlin")
#   EXISTCA_CAORG       (eg "Example Org")
#   EXISTCA_CAOU        (eg "CA")
#   EXISTCA_CAEMAIL     (eg "ca@example.org")
#   EXISTCA_HOME        (eg /usr/local/eXistCA)
#   EXISTCA XMLOUT
#   PKI_BASE
#
# This script returns the following exit codes:
#   0  - success
#   1  - fail: parameter problem
#   2  - fail: CA init


# required env vars as documented above
REQ_ENV="\
 EXISTCA_CAPASS \
 EXISTCA_CANAME \
 EXISTCA_CAKEYSIZE \
 EXISTCA_CAEXPIRE \
 EXISTCA_CACOUNTRY \
 EXISTCA_CAPROVINCE \
 EXISTCA_CACITY \
 EXISTCA_CAORG \
 EXISTCA_CAOU \
 EXISTCA_CAEMAIL \
 EXISTCA_HOME \
 EXISTCA_XMLOUT \
 PKI_BASE \
"

#FAKE="echo"

# dump CA and server data as XML
dump_xml () {
    ca_crt=`cat $EASYRSA_PKI/ca.crt`
    ca_key=`cat $EASYRSA_PKI/private/ca.key`
    ca_serial=`tr -dc "[:xdigit:]" <$EASYRSA_PKI/serial`
    exp_date=`openssl x509 -text -in $EASYRSA_PKI/ca.crt | grep "Not After" | sed 's/.*Not After : //;'`
    printf "
<CA name=\"$THIS_CA\" nicename=\"$EXISTCA_CANAME\">
  <keysize>$EXISTCA_CAKEYSIZE</keysize>
  <expire>$EXISTCA_CAEXPIRE</expire>
  <capass>$EXISTCA_CAPASS</capass>
  <cacert>$ca_crt</cacert>
  <cakey>$ca_key</cakey>
  <current-serial>$ca_serial</current-serial>
  <expiry-date>$exp_date</expiry-date>
  <dnsname/>
  <country>$EXISTCA_CACOUNTRY</country>
  <province>$EXISTCA_CAPROVINCE</province>
  <city>$EXISTCA_CACITY</city>
  <org>$EXISTCA_CAORG</org>
  <org-unit>$EXISTCA_CAOU</org-unit>
  <email>$EXISTCA_CAEMAIL</email>
  <certs/>
</CA>
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
THIS_CA=`echo -n "$EXISTCA_CANAME" | tr -cd '[:alnum:]'`

# verify keysize user input
if ! verify_rsakeysize $EXISTCA_CAKEYSIZE; then
    logmsg "ERROR \"$THIS_CA\" - key size $EXISTCA_CAKEYSIZE not supported"
    err=1
fi
# verify expire value is postive integer
if ! verify_posint $EXISTCA_CAEXPIRE; then
    logmsg "ERROR \"$THIS_CA\" - invalid $EXISTCA_CAEXPIRE data"
    err=1
fi

# err out with exit code 1 (parameter problem)
if [ $err -ne 0 ]; then
    logmsg "ERROR \"$THIS_CA\" - creating CA: parameter problem"
    printf "<CA/>"
    exit 1
fi


### setup env for easyrsa

# define EASYRSA_PKI to point to $THIS_CA directory
export EASYRSA_PKI=${PKI_BASE}/${THIS_CA}

export EASYRSA_KEY_SIZE=$EXISTCA_CAKEYSIZE
export EASYRSA_CA_EXPIRE=$EXISTCA_CAEXPIRE
export EASYRSA_REQ_CN=$EXISTCA_CANAME
export EASYRSA_REQ_COUNTRY=$EXISTCA_CACOUNTRY
export EASYRSA_REQ_PROVINCE=$EXISTCA_CAPROVINCE
export EASYRSA_REQ_CITY=$EXISTCA_CACITY
export EASYRSA_REQ_ORG=$EXISTCA_CAORG
export EASYRSA_REQ_OU=$EXISTCA_CAOU
export EASYRSA_REQ_EMAIL=$EXISTCA_CAEMAIL

# reset and export auth related vars
EXISTCA_AUTHIN=
EXISTCA_AUTHOUT=
export EXISTCA_AUTHIN EXISTCA_AUTHOUT EXISTCA_CAPASS

cd $EASYRSA

# initialize CA infrastructure
$FAKE sh ./easyrsa init-pki
if [ $? -ne 0 ]; then
    logmsg "ERROR \"$THIS_CA\" - failed to initialize PKI directories"
    err=1
fi

# copy pregenerated DH parameters (generating them may take a long time)
# not required for the CA, may be useful for applications
$FAKE cp $EXISTCA_HOME/dh-samples/dh*.pem $EASYRSA_PKI/
if [ $? -ne 0 ]; then
    logmsg "ERROR \"$THIS_CA\" - failed to copy DH parameters"
    err=1
fi

# create CA cert
EXISTCA_AUTHIN=
EXISTCA_AUTHOUT="env:EXISTCA_CAPASS"
$FAKE sh ./easyrsa build-ca
if [ $? -ne 0 ]; then
    logmsg "ERROR \"$THIS_CA\" - failed to create CA cert"
    err=1
fi

# err out with exit code 2 (CA init)
if [ $err -ne 0 ]; then
    logmsg "ERROR creating CA \"$THIS_CA\": CA init"
    printf "<CA/>"
    exit 2
fi

# copy generated CA cert to .cacert suffix, mime type for browser import
cp $EASYRSA_PKI/ca.crt $EASYRSA_PKI/ca.cacert

# dump XML data to stdout regardless of possible errors (some XML fields 
# may be left blank if server cert failed)
dump_xml


exit 0

