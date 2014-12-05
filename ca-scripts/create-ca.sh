#!/bin/sh 

# create a CA instance, including these steps
# . setup required dirs
# . init CA infrastructure
# . create CA key and cert
# . create SSL server cert for eXist web frontend
# . install SSL server cert into eXist jetty and reload
# . fixup network setup if required
#
# The following environment vars need to be passed from the caller:
#   EXISTCA_CAPASS      (eg "craps")
#   EXISTCA_CANAME      (eg "Example CA")
#   EXISTCA_CAKEYSIZE   (eg 4096)
#   EXISTCA_CAEXPIRE    (eg 3650)
#   EXISTCA_SRVNAME     (eg "existca.example.org")
#   EXISTCA_SRVKEYSIZE  (eg 2048)
#   EXISTCA_SRVEXPIRE   (eg 1825)
#   EXISTCA_SRVPASS     (eg "secret")
#   EXISTCA_HOME        (eg /usr/local/eXistCA)
#   PKI_BASE

# required env vars as documented above
REQ_ENV="\
 EXISTCA_CAPASS \
 EXISTCA_CANAME \
 EXISTCA_CAKEYSIZE \
 EXISTCA_CAEXPIRE \
 EXISTCA_SRVNAME \
 EXISTCA_SRVKEYSIZE \
 EXISTCA_SRVEXPIRE \
 EXISTCA_SRVPASS \
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
    logmsg "ERROR - refuse to work on incomplete data"
    #err_out 1
    exit 1
fi

# XXX validate all user provided input data!

err=0

# cleanup obscure chars out of passed CA name, for use as file name
THIS_CA=`echo -n "$EXISTCA_CANAME" | tr -cd '[:alnum:]'`

# cleanup obscure chars out of passed server name, for use as file name
THIS_SRV=`echo -n "$EXISTCA_SRVNAME" | tr -cd '[:alnum:].-'`

# define EASYRSA_PKI to point to $THIS_CA directory
export EASYRSA_PKI=${PKI_BASE}/${THIS_CA}

export EASYRSA_KEY_SIZE=$EXISTCA_CAKEYSIZE
export EASYRSA_CA_EXPIRE=$EXISTCA_CAEXPIRE
export EASYRSA_REQ_CN=$EXISTCA_CANAME
#export EASYRSA_REQ_COUNTRY="DE"
#export EASYRSA_REQ_PROVINCE="Berlin"
#export EASYRSA_REQ_CITY="Berlin"
#export EASYRSA_REQ_ORG="Example Org"
#export EASYRSA_REQ_OU=""
#export EASYRSA_REQ_EMAIL="ca@example.org"

EXISTCA_AUTHIN=
EXISTCA_AUTHOUT=
EXISTCA_AUTHPASS=
export EXISTCA_AUTHIN EXISTCA_AUTHOUT EXISTCA_AUTHPASS
export EXISTCA_CAPASS EXISTCA_SRVPASS

cd $EASYRSA

# initialize CA infrastructure
$FAKE ./easyrsa init-pki
if [ $? -ne 0 ]; then
    logmsg "ERROR [$THIS_CA] - failed to initialize PKI directories"
    #err=1
    #err_out 2
    exit 2
fi

# copy pregenerated DH parameters (generating them may take a long time)
# not required for the CA, may be useful for applications
$FAKE cp $EXISTCA_HOME/dh-samples/dh*.pem $EASYRSA_PKI/
if [ $? -ne 0 ]; then
    logmsg "ERROR [$THIS_CA] - failed to copy DH parameters"
    err=1
fi

# create CA cert
EXISTCA_AUTHIN=
EXISTCA_AUTHOUT="env:EXISTCA_CAPASS"
$FAKE ./easyrsa build-ca
if [ $? -ne 0 ]; then
    logmsg "ERROR [$THIS_CA] - failed to create CA cert"
    #err=1
    #err_out 3
    exit 3
fi

### create server cert for eXist webserver

# server cert data
export EASYRSA_KEY_SIZE=$EXISTCA_SRVKEYSIZE
export EASYRSA_CERT_EXPIRE=$EXISTCA_SRVEXPIRE
export EASYRSA_REQ_CN=$THIS_SRV

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
    logmsg "ERROR [$THIS_CA] - failed to generate web server certificate request"
    err=1
fi

# sign web server cert request
EXISTCA_AUTHIN="env:EXISTCA_CAPASS"
EXISTCA_AUTHOUT=
$FAKE ./easyrsa sign-req server "$EASYRSA_REQ_CN"
if [ $? -ne 0 ]; then
    logmsg "ERROR [$THIS_CA] - failed to sign web server certificate"
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
    logmsg "ERROR [$THIS_CA] - failed to pkcs12 export web server certificate"
    err=1
fi

# install generated web server cert into eXist config and reload eXist
export SERVER_P12=${PKI_BASE}/${THIS_CA}/private/${EXISTCA_SRVNAME}.p12
export CA_CERT=${PKI_BASE}/${THIS_CA}/ca.crt
export EXISTCA_HOME THIS_CA

$FAKE sh $EXISTCA_HOME/reconfig-jetty.sh
if [ $? -ne 0 ]; then
    logmsg "ERROR [$THIS_CA] - failed to reconfig jetty"
    err=1
fi

# check/fix hostname/network config to match web server name


# dump XML data to stdout
ca_crt=`cat $EASYRSA_PKI/ca.crt`
ca_key=`cat $EASYRSA_PKI/private/ca.key`
srv_crt=`cat $EASYRSA_PKI/issued/${THIS_SRV}.crt`
srv_key=`cat $EASYRSA_PKI/private/${THIS_SRV}.key`
#srv_pkcs12=`cat $EASYRSA_PKI/private/${THIS_SRV}.p12`
srv_req=`cat $EASYRSA_PKI/reqs/${THIS_SRV}.req`
ca_serial=`tr -dc '[:xdigit:]' <$EASYRSA_PKI/serial`
#read status expire serial unkn cn
 
printf "
<CA name=\"$THIS_CA\" nicename=\"$EXISTCA_CANAME\" servername=\"$THIS_SRV\">
  <keysize>$EXISTCA_CAKEYSIZE</keysize>
  <expire>$EXISTCA_CAEXPIRE</expire>
  <capass>$EXISTCA_CAPASS<capass>
  <cacert>$ca_crt</cacert>
  <cakey>$ca_key</cakey>
  <current-serial>$ca_serial</current-serial>
  <certs>
    <cert name=\"$THIS_SRV\" nicename=\"$EXISTCA_SRVNAME\">
      <certtype>server</certtype>
      <serial></serial>
      <status></status>
      <certpass>$EXISTCA_SRVPASS</certpass>
      <cert>$srv_crt</cert>
      <key>$srv_key</key>
      <pkcs12>$srv_pkcs12</pkcs12>
      <req>$srv_req</req>
    </cert>
  </certs>
</CA>
"

if [ $err -ne 0 ]; then
    logmsg "ERROR creating CA [$THIS_CA]"
    exit 1
else
    exit 0
fi

