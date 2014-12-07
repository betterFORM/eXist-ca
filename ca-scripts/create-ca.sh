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
#   EXISTCA_SRVNAME     (eg "existca.example.org")
#   EXISTCA_SRVKEYSIZE  (eg 2048)
#   EXISTCA_SRVEXPIRE   (eg 1825)
#   EXISTCA_SRVPASS     (eg "secret")
#   EXISTCA_SRVCOUNTRY   (eg "DE")
#   EXISTCA_SRVPROVINCE  (eg "Berlin")
#   EXISTCA_SRVCITY      (eg "Berlin")
#   EXISTCA_SRVORG       (eg "Example Org")
#   EXISTCA_SRVOU        (eg "CA")
#   EXISTCA_SRVEMAIL     (eg "ca@example.org")
#   EXISTCA_HOME        (eg /usr/local/eXistCA)
#   PKI_BASE
#
# This script returns the following exit codes:
#   0  - success
#   1  - fail: parameter problem
#   2  - fail: CA init
#   3  - fail: server cert
#   4  - fail: jetty reconfig
#   5  - fail: network reconfig


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
 EXISTCA_SRVNAME \
 EXISTCA_SRVKEYSIZE \
 EXISTCA_SRVEXPIRE \
 EXISTCA_SRVPASS \
 EXISTCA_SRVCOUNTRY \
 EXISTCA_SRVPROVINCE \
 EXISTCA_SRVCITY \
 EXISTCA_SRVORG \
 EXISTCA_SRVOU \
 EXISTCA_SRVEMAIL \
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

# dump CA and server data as XML
dump_xml () {
    ca_crt=`cat $EASYRSA_PKI/ca.crt`
    ca_key=`cat $EASYRSA_PKI/private/ca.key`
    srv_crt=`cat $EASYRSA_PKI/issued/${THIS_SRV}.crt`
    srv_key=`cat $EASYRSA_PKI/private/${THIS_SRV}.key`
    #srv_pkcs12=`cat $EASYRSA_PKI/private/${THIS_SRV}.p12`
    srv_pkcs12='this is binary and needs encoding'
    srv_req=`cat $EASYRSA_PKI/reqs/${THIS_SRV}.req`
    ca_serial=`tr -dc '[:xdigit:]' <$EASYRSA_PKI/serial`
    read status expire serial unkn cn <<INDEX
$(grep "$THIS_SRV" $EASYRSA_PKI/index.txt)
INDEX
    exp_date=`openssl x509 -text -in $EASYRSA_PKI/issued/${THIS_SRV}.crt | grep "Not After" | sed 's/.*Not After : //;`
    printf "
<CA name=\"$THIS_CA\" nicename=\"$EXISTCA_CANAME\" servername=\"$THIS_SRV\">
  <keysize>$EXISTCA_CAKEYSIZE</keysize>
  <expire>$EXISTCA_CAEXPIRE</expire>
  <capass>$EXISTCA_CAPASS<capass>
  <cacert>$ca_crt</cacert>
  <cakey>$ca_key</cakey>
  <current-serial>$ca_serial</current-serial>
  <expiry-date>$exp_date</expiry-date>
  <country>$EXISTCA_CACOUNTRY</country>
  <province>$EXISTCA_CAPROVINCE</province>
  <city>$EXISTCA_CACITY</city>
  <org>$EXISTCA_CAORG</org>
  <org-unit>$EXISTCA_CAOU</org-unit>
  <email>$EXISTCA_CAEMAIL</email>
  <certs>
    <cert name=\"$THIS_SRV\" nicename=\"$EXISTCA_SRVNAME\">
      <certtype>server</certtype>
      <serial>$serial</serial>
      <status>$status</status>
      <expire-timestamp>$expire</expire-timestamp>
      <certpass>$EXISTCA_SRVPASS</certpass>
      <country>$EXISTCA_SRVCOUNTRY</country>
      <province>$EXISTCA_SRVPROVINCE</province>
      <city>$EXISTCA_SRVCITY</city>
      <org>$EXISTCA_SRVORG</org>
      <org-unit>$EXISTCA_SRVOU</org-unit>
      <email>$EXISTCA_SRVEMAIL</email>
      <cert>$srv_crt</cert>
      <key>$srv_key</key>
      <pkcs12>$srv_pkcs12</pkcs12>
      <req>$srv_req</req>
    </cert>
  </certs>
</CA>
"
}

# source common script vars
. $EXISTCA_HOME/script-vars.sh

err=0

# env sanity checks
if ! checkenv $REQ_ENV; then
    logmsg "ERROR - refuse to work on incomplete data"
    err=1
fi

# validate user provided input data!

# verify keysize user input
if ! verify_rsakeysize $EXISTCA_CAKEYSIZE; then
    logmsg "ERROR - key size $EXISTCA_CAKEYSIZE not supported"
    err=1
fi
if ! verify_rsakeysize $EXISTCA_SRVKEYSIZE; then
    logmsg "ERROR - key size $EXISTCA_SRVKEYSIZE not supported"
    err=1
fi
# verify expire value is postive integer
if ! verify_expire $EXISTCA_CAEXPIRE; then
    logmsg "ERROR - invalid $EXISTCA_CAEXPIRE data"
    err=1
fi
if ! verify_expire $EXISTCA_SRVEXPIRE; then
    logmsg "ERROR - invalid $EXISTCA_SRVEXPIRE data"
    err=1
fi

# cleanup obscure chars out of passed CA name, for use as file name
THIS_CA=`echo -n "$EXISTCA_CANAME" | tr -cd '[:alnum:]'`

# cleanup obscure chars out of passed server name, for use as file name
THIS_SRV=`echo -n "$EXISTCA_SRVNAME" | tr -cd '[:alnum:].-'`

# err out with exit code 1 (parameter problem)
if [ $err -ne 0 ]; then
    logmsg "ERROR creating CA \"$THIS_CA\": parameter problem"
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
EXISTCA_AUTHPASS=
export EXISTCA_AUTHIN EXISTCA_AUTHOUT EXISTCA_AUTHPASS
export EXISTCA_CAPASS EXISTCA_SRVPASS

cd $EASYRSA

# initialize CA infrastructure
$FAKE ./easyrsa init-pki
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
$FAKE ./easyrsa build-ca
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

### create server cert for eXist webserver

# server cert data
export EASYRSA_KEY_SIZE=$EXISTCA_SRVKEYSIZE
export EASYRSA_CERT_EXPIRE=$EXISTCA_SRVEXPIRE
export EASYRSA_REQ_CN=$THIS_SRV
export EASYRSA_REQ_COUNTRY=$EXISTCA_SRVCOUNTRY
export EASYRSA_REQ_PROVINCE=$EXISTCA_SRVPROVINCE
export EASYRSA_REQ_CITY=$EXISTCA_SRVCITY
export EASYRSA_REQ_ORG=$EXISTCA_SRVORG
export EASYRSA_REQ_OU=$EXISTCA_SRVOU
export EASYRSA_REQ_EMAIL=$EXISTCA_SRVEMAIL

# create web server cert request
if [ -n "$EXISTCA_SRVPASS" ]; then
    EXISTCA_AUTHOUT="env:EXISTCA_SRVPASS"
else
    EXISTCA_AUTHOUT=
    genreq_opt=nopass
fi
EXISTCA_AUTHIN=
$FAKE ./easyrsa gen-req "$EASYRSA_REQ_CN" $genreq_opt
if [ $? -ne 0 ]; then
    logmsg "ERROR \"$THIS_CA\" - failed to generate web server certificate request"
    err=1
fi

# sign web server cert request
EXISTCA_AUTHIN="env:EXISTCA_CAPASS"
EXISTCA_AUTHOUT=
$FAKE ./easyrsa sign-req server "$EASYRSA_REQ_CN"
if [ $? -ne 0 ]; then
    logmsg "ERROR \"$THIS_CA\" - failed to sign web server certificate"
    err=1
fi

# build PKCS12 cert data structure
if [ -n "$EXISTCA_SRVPASS" ]; then
    EXISTCA_AUTHIN="env:EXISTCA_SRVPASS"
    EXISTCA_AUTHPASS="env:EXISTCA_SRVPASS"
else
    EXISTCA_AUTHIN=
    EXISTCA_AUTHPASS="env:EXISTCA_EXPORTPASS"
fi
$FAKE ./easyrsa export-p12 "$EASYRSA_REQ_CN"
if [ $? -ne 0 ]; then
    logmsg "ERROR \"$THIS_CA\" - failed to pkcs12 export web server certificate"
    err=1
fi

### dump XML data to stdout regardless of possible errors (some XML fields 
### may be left blank if server cert failed)
dump_xml

# err out with exit code 3 (server cert)
if [ $err -ne 0 ]; then
    logmsg "ERROR creating CA \"$THIS_CA\": server cert"
    dump_xml
    exit 3
fi

# install generated web server cert into eXist config
export SERVER_P12=${PKI_BASE}/${THIS_CA}/private/${EXISTCA_SRVNAME}.p12
export CA_CERT=${PKI_BASE}/${THIS_CA}/ca.crt
export EXISTCA_HOME THIS_CA

$FAKE sh $EXISTCA_HOME/reconfig-jetty.sh
if [ $? -ne 0 ]; then
    logmsg "ERROR \"$THIS_CA\" - failed to reconfig jetty"
    # err out with exit code 4 (jetty reconfig)
    exit 4
fi

### check/fix hostname/network config to match web server name

#$FAKE sh $EXISTCA_HOME/reconfig-net.sh
#if [ $? -ne 0 ]; then
#    logmsg "ERROR \"$THIS_CA\" - failed to reconfig network"
#    # err out with exit code 5 (network reconfig)
#    exit 5
#fi


exit 0

