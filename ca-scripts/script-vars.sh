#!/bin/sh

PKI_BASE=/tmp/pki


### Common enviroment variables that get passed to easyrsa

# basedir for the EasyRSA software.  needed to call easyrsa scripts
export EASYRSA=$BASEDIR/resources/easyrsa3

# $EASYRSA_PKI is the heart of the CA, this directory contains all 
# infrastructure files and generated keys and certs.  These are PERSISTENT 
# data that must be kept over the lifetime of the CA.  This is also extremely 
# CRITICAL data, loss of this data will destroy the CA and defunct all 
# services using it.
#
# For now this ia subdir below $EASYRSA/ (EasyRSA default setting)
# This should be pseudo filesystem mapped into eXist DB later.
#export EASYRSA_PKI=$BASEDIR/pki

# set batch mode
export EASYRSA_BATCH=yes

# reset some env vars
export EASYRSA_REQ_ORG=
export EASYRSA_REQ_OU=
export EASYRSA_REQ_CITY=
export EASYRSA_REQ_PROVINCE=
export EASYRSA_REQ_COUNTRY=
export EASYRSA_REQ_EMAIL=
export EASYRSA_NS_COMMENT=

# do not parse any kind of easyrsa vars file
#export EASYRSA_NO_VARS

# OpenSSL config file, defaults are usually fine
#export EASYRSA_SSL_CONF=$BASEDIR/data/openssl.cnf

