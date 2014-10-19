#!/bin/sh 

# This script assumes $VARS_FILE has been created correctly with 
# parameters from XForms.  It does NOT create $VARS_FILE.


### ---- cruft, goes away later
# just some info gathering (to understand paths, env etc)
# this cruft goes away when I understand how to call the scripts correctly
echo "pwd:"
pwd
echo "environment:"
env
echo "cmdline:"
echo $*
#echo "stdin:"
#while read line; do echo $line; done

#DEBUG=1
[ -n "$DEBUG" ] && FAKE="echo"

#TESTRUN=1         # will delete previously generated CA data
### ---- end cruft


# need $BASEDIR to locate other dirs relative to this
BASEDIR=`pwd`

# $DATADIR holds some config files
DATADIR=$BASEDIR/data

# basedir for the EasyRSA software.  needed to setup and call easyrsa scripts
EASYRSA_HOME=$BASEDIR/resources/easyrsa3-test

# $CERTDIR is the heart of the CA, this directory contains all infrastructure 
# files and generated keys and certs.  These are PERSISTENT data that must be 
# kept over the lifetime of the CA.  This is also extremely CRITICAL data, 
# loss of this data will destroy the CA and defunct all services using it.
#
# For now this ia subdir below easyrsa/ (EasyRSA default setting)
# This should be pseudo filesystem mapped into eXist DB later.
CERTDIR=$EASYRSA_HOME/pki

# $VARS_FILE is similar to the EasyRSA "vars" file.  It holds the config 
# values that were entered in XForms.
VARS_FILE=$DATADIR/easyrsa-vars

# $OPENSSL_CONF is shipped with eXistCA and located in $DATADIR.  Currently 
# this defaults to the file that is shipped with EasyRSA.  
#OPENSSL_CONF=$DATADIR/openssl.cnf


### ---- cruft, goes away later
# steps to create an initial CA with easyrsa2
#cd $EASYRSA_HOME
#. ./vars
#./clean-all
#./build-dh
#./pkitool --initca --pass
#
# steps to create an initial CA with easyrsa3
#./easyrsa init-pki
#./easyrsa build-ca
### ---- end cruft


# config data via env vars
export EASYRSA=$EASYRSA_HOME
export EASYRSA_PKI=$CERTDIR
export EASYRSA_VARS_FILE=$VARS_FILE
export EASYRSA_BATCH=yes
[ -n "$OPENSSL_CONF" ] && export EASYRSA_SSL_CONF=$OPENSSL_CONF

# source other env vars created from XForms
. $VARS_FILE

err=0
cd $EASYRSA_HOME

# setup PKI dir
$FAKE ./easyrsa init-pki
if [ $? -ne 0 ]; then
    echo "failed to initialize PKI directories"
    err=1
fi

# copy pregenerated DH parameters instead of generating them, takes a long time
$FAKE cp $DATADIR/dh*.pem $CERTDIR/
if [ $? -ne 0 ]; then
    echo "failed to copy DH parameters"
    err=1
fi

# create CA cert
$FAKE echo $CA_PASS | ./easyrsa build-ca
if [ $? -ne 0 ]; then
    echo "failed to create CA cert"
    err=1
fi

if [ $err -ne 0 ]; then
    echo "ERROR creating CA"
    exit 1
else
    exit 0
fi

