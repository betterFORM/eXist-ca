#!/bin/sh

# required env vars as documented above
export REQ_ENV="\
 SERVER_P12 \
 CA_CERT \
 THIS_CA \
 JAVA_HOME \
 JETTY_HOME \
 EXISTCA_SRVPASS \
 EXISTCA_HOME \
 PKI_BASE
"
# EXISTCA_EXPORTPASS \

#FAKE=echo

# source common script vars
. $EXISTCA_HOME/script-vars.sh

# env sanity checks
if ! checkenv $REQ_ENV; then
    echo "ERROR - refuse to work on incomplete data"
    exit 1
fi

# caller is expected to set the environment var SERVER_P12 to point to a 
# PKCS#12 encoded server certificate 
#SERVER_P12=/tmp/pki/ExampleCA/private/existca.example.org.p12

JETTY_KEYSTORE=${JETTY_HOME}/etc/keystore

# generate random keystore password
RANDPW=`dd if=/dev/urandom bs=1024 count=1 2>/dev/null | md5`
# encrypt random password
CRYPTPW=`$JAVA_HOME/bin/java -cp ${JETTY_HOME}/lib/jetty-util*.jar org.eclipse.jetty.util.security.Password whatever "$RANDPW" 2>&1 | grep CRYPT`

# copy empty example keystore and set password
cp $EXISTCA_HOME/jetty-samples/example-keystore $JETTY_KEYSTORE
DEFPW=secret
#USE_PW=testing
USE_PW=$DEFPW
#USE_PW=$RANDPW

#$FAKE $JAVA_HOME/bin/keytool -storepasswd -new "$USE_PW" -storepass "$DEFPW" -keystore $JETTY_KEYSTORE

# import PKCS12 into keystore
$FAKE $JAVA_HOME/bin/keytool -importkeystore -srckeystore $SERVER_P12 -srcstoretype PKCS12 -destkeystore $JETTY_KEYSTORE -srcalias 1 -destalias jetty -deststorepass "$USE_PW" -srcstorepass "$EXISTCA_EXPORTPASS"
#$FAKE $JAVA_HOME/bin/keytool -importkeystore -srckeystore $SERVER_P12 -srcstoretype PKCS12 -destkeystore $JETTY_KEYSTORE -srcalias 1 -destalias jetty -deststorepass "$USE_PW" -srcstorepass "$EXISTCA_SRVPASS"

# also import CA cert explicitly, avoids complaints from jetty
#$FAKE $JAVA_HOME/bin/keytool -import -alias $THIS_CA -file $CA_CERT -keystore $JETTY_KEYSTORE -storepass "$USE_PW" -noprompt

# rewrite jetty.xml file
cd ${JETTY_HOME}/etc && cp jetty.xml jetty.xml.bak \
#    && sed -e "s/8443/443/;" <jetty.xml.bak >jetty.xml
#    && sed -e "s/secret/${USE_PW}/; s/8443/443/;" <jetty.xml.bak >jetty.xml
#    && sed -e "s/secret/${CRYPTPW}/; s/8443/443/;" <jetty.xml.bak >jetty.xml

# restart exist
#/etc/rc.d/exist restart

