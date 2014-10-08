#!/bin/sh 

# just some info gathering (to understand paths, env etc)
# this cruft goes away when I understand tow to call scripts correctly
echo "pwd:"
pwd
echo "environment:"
env
echo "cmdline:"
echo $*


TESTRUN=1         # will delete previously generated CA data

EASYRSA_HOME=/some/where/easyrsa2
CERT_DIR=$EASYRSA_HOME/keys


# this script assumes $EASYRSA_HOME/vars has been created correctly with 
# parameters from XForms.  It does NOT create $EASYRSA_HOME/vars.

# traditional steps to create in initial CA with easyrsa
#cd $EASYRSA_HOME
#. ./vars
#./clean-all
#./build-dh
#./pkitool --initca --pass
