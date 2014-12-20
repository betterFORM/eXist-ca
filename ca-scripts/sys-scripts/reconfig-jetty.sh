#!/bin/sh

# modify jetty configuration
#
# The following environment vars need to be passed from the caller 
# (vars may have no value, but must be present in the environment):
#   SERVER_P12          (eg /tmp/pki/ExampleCA/private/existca.example.org.p12)
#   JAVA_HOME
#   JETTY_HOME
#   JETTY_PORT          (eg 443)
#   EXISTCA_HOME        (eg /usr/local/eXistCA)
#   EXISTCA SRVPASS
#   EXISTCA EXPORTPASS
#
# This script returns the following exit codes:
#   0  - success
#   1  - fail: parameter problem
#   2  - fail: jetty keystore setup
#   3  - fail: jetty configuration


# required env vars as documented above
export REQ_ENV="\
 SERVER_P12 \
 JAVA_HOME \
 JETTY_HOME \
 JETTY_PORT \
 EXISTCA_HOME \
 EXISTCA_SRVPASS \
 EXISTCA_EXPORTPASS \
"

#FAKE=echo

# whether to store keystore secrets crypted or plaintext in jetty.xml
#ENCRYPT_KEYSTORE_SECRETS=yes

# source common script vars
. $EXISTCA_HOME/script-vars.sh

err=0

# env sanity checks
if ! checkenv $REQ_ENV; then
    logmsg "ERROR - refuse to work on incomplete data"
    exit 1
fi

# caller is expected to set the environment var SERVER_P12 to point to a 
# PKCS#12 encoded server certificate 
if [ ! -f "$SERVER_P12" ]; then
    logmsg "server cert PKCS12 file not found"
    exit 1
fi

# verify jetty port value is postive integer
if ! verify_posint $JETTY_PORT; then
    logmsg "ERROR - invalid $JETTY_PORT"
    exit 1
fi


JETTY_SAMPLES=$EXISTCA_HOME/sys-scripts/jetty-samples

### setup jetty keystore

JETTY_KEYSTORE=${JETTY_HOME}/etc/keystore
HARDCODED_PW=secret
USE_PW=$HARDCODED_PW
#RANDPW=`dd if=/dev/urandom bs=1024 count=1 2>/dev/null | md5`
#USE_PW=$RANDPW
$FAKE cp $JETTY_SAMPLES/example-keystore $JETTY_KEYSTORE
if [ $? -ne 0 ]; then
    logmsg "ERROR - failed to install default jetty keystore"
    err=1
fi
if [ "$USE_PW" != "$HARDCODED_PW" ]; then
    # set new password on keystore
    $FAKE $JAVA_HOME/bin/keytool -storepasswd -new "$USE_PW" \
	-storepass "$HARDCODED_PW" -keystore $JETTY_KEYSTORE
    if [ $? -ne 0 ]; then
	logmsg "ERROR - failed to set password on jetty keystore"
	err=1
    fi
fi
# build password replacement string for jetty.xml
if [ "$ENCRYPT_KEYSTORE_SECRETS" == yes ]; then
    ENCODED_PW=`$JAVA_HOME/bin/java -cp ${JETTY_HOME}/lib/jetty-util*.jar org.eclipse.jetty.util.security.Password whatever "$USE_PW" 2>&1 | grep CRYPT`
else
    ENCODED_PW=$USE_PW
fi
if [ "$ENCODED_PW" != "$HARDCODED_PW" ]; then
    SED_PW="s/${HARDCODED_PW}/${ENCODED_PW}/;"
fi

# import server cert PKCS12 into keystore
PKCS12_PASS=$EXISTCA_EXPORTPASS
#PKCS12_PASS=$EXISTCA_SRVPASS
$FAKE $JAVA_HOME/bin/keytool -importkeystore -srckeystore $SERVER_P12 \
    -srcstoretype PKCS12 -destkeystore $JETTY_KEYSTORE -srcalias 1 \
    -destalias jetty -deststorepass "$USE_PW" -srcstorepass "$PKCS12_PASS"
if [ $? -ne 0 ]; then
    logmsg "ERROR - failed to import server cert PKCS12"
    err=1
fi

# also import CA cert explicitly, avoids complaints from jetty
# XXX probably not needed.  expects CA_CERT and THIS_CA env vars
#$FAKE $JAVA_HOME/bin/keytool -import -alias $THIS_CA -file $CA_CERT \
#    -keystore $JETTY_KEYSTORE -storepass "$USE_PW" -noprompt

# err out with exit code 2 (jetty keystore)
if [ $err -ne 0 ]; then
    logmsg "ERROR setting up jetty keystore"
    exit 2
fi


### setup jetty

# rewrite jetty.xml file
JETTY_XML_SRC=$JETTY_SAMPLES/example-jetty.xml
HARDCODED_PORT=8443
if [ -n "$JETTY_PORT" -a "$JETTY_PORT" -ne "$HARDCODED_PORT" ]; then
    SED_PORT="s/${HARDCODED_PORT}/${JETTY_PORT}/;"
fi
$FAKE sed -e "$SED_PW $SED_PORT" <$JETTY_XML_SRC >${JETTY_HOME}/etc/jetty.xml
if [ $? -ne 0 ]; then
    logmsg "ERROR - failed to modify jetty.xml"
    err=1
fi

# patch webdefaults.xml to support cert mime types
# XXX work in progress, for now we copy our sample file
$FAKE cp $JETTY_SAMPLES/example-webdefault.xml $JETTY_HOME/etc
if [ $? -ne 0 ]; then
    logmsg "ERROR - failed to install default jetty webdefault.xml"
    err=1
fi

# err out with exit code 3 (jetty config)
if [ $err -ne 0 ]; then
    logmsg "ERROR configuring jetty"
    exit 3
fi


### check/fix hostname/network config to match web server name

#$FAKE sh $EXISTCA_HOME/reconfig-net.sh
#if [ $? -ne 0 ]; then
#    logmsg "ERROR - failed to reconfig network"
#    # err out with exit code 5 (network reconfig)
#    exit 5
#fi

# restart exist
#$FAKE /etc/rc.d/exist restart


exit 0
