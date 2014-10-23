#!/bin/sh 

# This script assumes $EASYRSA_VARS_FILE has been created correctly with 
# parameters from XForms.  It does NOT create $EASYRSA_VARS_FILE itself.


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
### ---- end cruft


# need $BASEDIR to locate other dirs relative to this
BASEDIR=`pwd`

# source common script vars
. $BASEDIR/ca-scripts/vars.sh

# source other env vars created from XForms
. $EASYRSA_VARS_FILE

err=0
cd $EASYRSA_HOME

# setup PKI dir
$FAKE ./easyrsa init-pki
if [ $? -ne 0 ]; then
    echo "failed to initialize PKI directories"
    err=1
fi

# copy pregenerated DH parameters instead of generating them, takes a long time
$FAKE cp $BASEDIR/data/dh*.pem $EASYRSA_PKI/
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

