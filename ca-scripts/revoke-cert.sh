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

# strip whitespace (and maybe other) from Common Name, for use as file name
ENTITY=`echo $EASYRSA_REQ_CN | tr -d ' '`

err=0
cd $EASYRSA

# revoke cert
$FAKE echo "$CERT_PASS" | ./easyrsa revoke "$ENTITY"
if [ $? -ne 0 ]; then
    echo "ERROR creating $CERTTYPE certificate"
    exit 1
fi

exit 0

