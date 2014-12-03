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
    echo "ERROR - refuse to work on incomplete data"
    exit 1
fi

# XXX validate all user provided input data!

err=0

# cleanup obscure chars out of passed CA name, for use as file name
THIS_CA=`echo -n "$EXISTCA_CANAME" | tr -cd '[:alnum:]'`

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

# initialize this CA
$FAKE ./easyrsa init-pki
if [ $? -ne 0 ]; then
    echo "ERROR [$THIS_CA] - failed to initialize PKI directories"
    err=1
fi

# copy pregenerated DH parameters (generating them may take a long time)
# not required for the CA, may be useful for applications
$FAKE cp $EXISTCA_HOME/dh-samples/dh*.pem $EASYRSA_PKI/
if [ $? -ne 0 ]; then
    echo "ERROR [$THIS_CA] - failed to copy DH parameters"
    err=1
fi

# create CA cert
EXISTCA_AUTHIN=
EXISTCA_AUTHOUT="env:EXISTCA_CAPASS"
$FAKE ./easyrsa build-ca
if [ $? -ne 0 ]; then
    echo "ERROR [$THIS_CA] - failed to create CA cert"
    err=1
fi

### create server cert for eXist webserver

# server cert data
export EASYRSA_KEY_SIZE=$EXISTCA_SRVKEYSIZE
export EASYRSA_CERT_EXPIRE=$EXISTCA_SRVEXPIRE
export EASYRSA_REQ_CN=$EXISTCA_SRVNAME

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
    echo "ERROR [$THIS_CA] - failed to generate web server certificate request"
    err=1
fi

# sign web server cert request
EXISTCA_AUTHIN="env:EXISTCA_CAPASS"
EXISTCA_AUTHOUT=
$FAKE ./easyrsa sign-req server "$EASYRSA_REQ_CN"
if [ $? -ne 0 ]; then
    echo "ERROR [$THIS_CA] - failed to sign web server certificate"
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
    echo "ERROR [$THIS_CA] - failed to pkcs12 export web server certificate"
    err=1
fi

# install generated web server cert into eXist config and reload eXist
export SERVER_P12=${PKI_BASE}/${THIS_CA}/private/${EXISTCA_SRVNAME}.p12
export EXISTCA_HOME

$FAKE sh $EXISTCA_HOME/reconfig-jetty.sh
if [ $? -ne 0 ]; then
    echo "ERROR [$THIS_CA] - failed to reconfig jetty"
    err=1
fi

# check/fix hostname/network config to match web server name


# return some XML data fragment
#<CA name="" servername="">
#  <capass><capass>
#  <cacert></cacert>
#  <cakey></cakey>
#  <current-serial></current-serial>
#  <certs>
#    <cert name="" type="" serial="" status="">
#      <certpass></certpass>
#      <cert></cert>
#      <key></key>
#      <pkcs12></pkcs12>
#      <req></req>
#    </cert>
#  </certs>
#</CA>

if [ $err -ne 0 ]; then
    echo "ERROR creating CA [$THIS_CA]"
    exit 1
else
    exit 0
fi

