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

# sample data for CA creation, to be passed from XQuery, hardcoded for now
EXISTCA_CANAME="Example CA"
EXISTCA_CAPASS="craps"
EXISTCA_CAKEYSIZE=4096
EXISTCA_CAEXPIRE=3650
EXISTCA_SRVNAME="existca.example.org"
EXISTCA_SRVKEYSIZE=2048
EXISTCA_SRVEXPIRE=1825

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


# XXX validate all user provided input data!

# need $BASEDIR to locate other dirs relative to this
BASEDIR=`pwd`

# source common script vars
. $BASEDIR/ca-scripts/script-vars.sh

err=0

# cleanup obscure chars out of passed CA name, for use as file name
THIS_CA=`echo -n "$EXISTCA_CANAME" | tr -cd '[:alnum:]'`

### XXX this is useless effort.  cleartext passwords are already passed into 
### the environment, don't bother getting them out there.
### symmetric encryption between eXist and the shell wrappers would be nice
###
## setup system PKI dir, store EXISTCA_CAPASS
#mkdir -p $PKI_BASE/priv \
#    && chmod 700 $PKI_BASE $PKI_BASE/priv \
#    && printf "%s" "${EXISTCA_CAPASS}" >$PKI_BASE/priv/${THIS_CA} \
#    && chmod 600 $PKI_BASE/priv/${THIS_CA}
#if [ $? -ne 0 ]; then
#    echo "ERROR [$THIS_CA] - failed to create PKI basedirs"
#    err=1
#fi
## drop EXISTCA_CAPASS from environment, export password options to easyrsa
#EXISTCA_CAPASS=
#export EXISTCA_AUTHIN="file:$PKI_BASE/priv/${THIS_CA}"
#export EXISTCA_AUTHOUT="file:$PKI_BASE/priv/${THIS_CA}"
###
### pass to easyrsa/openssl as environment vars
export EXISTCA_AUTHIN="env:EXISTCA_CAPASS"
export EXISTCA_AUTHOUT="env:EXISTCA_CAPASS"
export EXISTCA_AUTHPASS="pass:"
export EXISTCA_CAPASS

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

cd $EASYRSA

# initialize this CA
$FAKE ./easyrsa init-pki
if [ $? -ne 0 ]; then
    echo "ERROR [$THIS_CA] - failed to initialize PKI directories"
    err=1
fi

# copy pregenerated DH parameters (generating them may take a long time)
# not required for the CA, may be useful for applications
$FAKE cp $BASEDIR/data/dh*.pem $EASYRSA_PKI/
if [ $? -ne 0 ]; then
    echo "ERROR [$THIS_CA] - failed to copy DH parameters"
    err=1
fi

# create CA cert
$FAKE ./easyrsa build-ca
if [ $? -ne 0 ]; then
    echo "ERROR [$THIS_CA] - failed to create CA cert"
    err=1
fi

### create server cert for eXist webserver

# sample data for a server cert
export EASYRSA_KEY_SIZE=$EXISTCA_SRVKEYSIZE
export EASYRSA_CERT_EXPIRE=$EXISTCA_SRVEXPIRE
export EASYRSA_REQ_CN=$EXISTCA_SRVNAME

# create web server cert request
$FAKE ./easyrsa gen-req "$EASYRSA_REQ_CN" nopass
if [ $? -ne 0 ]; then
    echo "ERROR [$THIS_CA] - failed to generate web server certificate request"
    err=1
fi

# sign web server cert request
$FAKE ./easyrsa sign-req server "$EASYRSA_REQ_CN"
if [ $? -ne 0 ]; then
    echo "ERROR [$THIS_CA] - failed to sign web server certificate"
    err=1
fi

### install generated web server cert into eXist config and reload eXist

# build PKCS12 cert data structure, use empty export password
$FAKE ./easyrsa export-p12 "$EASYRSA_REQ_CN"
if [ $? -ne 0 ]; then
    echo "ERROR [$THIS_CA] - failed to pkcs12 export web server certificate"
    err=1
fi

# import PKCS12 into keystore
#$FAKE keytool ...

# rewrite/create jetty properties file

# check/fix hostname/network config to match web server name


if [ $err -ne 0 ]; then
    echo "ERROR creating CA [$THIS_CA]"
    exit 1
else
    exit 0
fi

