#!/bin/sh

# basedir for the EasyRSA software.  needed to call easyrsa scripts
export EASYRSA=$BASEDIR/resources/easyrsa3-test

# $EASYRSA_PKI is the heart of the CA, this directory contains all 
# infrastructure files and generated keys and certs.  These are PERSISTENT 
# data that must be kept over the lifetime of the CA.  This is also extremely 
# CRITICAL data, loss of this data will destroy the CA and defunct all 
# services using it.
#
# For now this ia subdir below $EASYRSA/ (EasyRSA default setting)
# This should be pseudo filesystem mapped into eXist DB later.
export EASYRSA_PKI=$BASEDIR/resources/easyrsa3-test/pki

# $VARS_FILE is similar to the EasyRSA "vars" file.  It holds the config 
# values that were entered in XForms.
export EASYRSA_VARS_FILE=$BASEDIR/data/easyrsa-vars

export EASYRSA_BATCH=yes
#export EASYRSA_SSL_CONF=$BASEDIR/data/openssl.cnf

