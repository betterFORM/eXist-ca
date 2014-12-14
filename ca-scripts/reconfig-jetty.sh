#!/bin/sh

# required env vars as documented above
export REQ_ENV="\
 SERVER_P12 \
 JAVA_HOME \
 JETTY_HOME \
 EXISTCA_HOME \
 EXISTCA_SRVPASS \
 EXISTCA_EXPORTPASS
"

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
# XXX probably not needed.  expects CA_CERT and THIS_CA env vars
#$FAKE $JAVA_HOME/bin/keytool -import -alias $THIS_CA -file $CA_CERT -keystore $JETTY_KEYSTORE -storepass "$USE_PW" -noprompt

# rewrite jetty.xml file
JETTY_XML_SRC=$EXISTCA_HOME/jetty-samples/example-jetty.xml
cp $JETTY_XML_SRC $JETTY_HOME/etc
#cd ${JETTY_HOME}/etc \
#    && sed -e "s/8443/443/;" <$JETTY_XML_SRC >jetty.xml
#    && sed -e "s/secret/${USE_PW}/; s/8443/443/;" <$JETTY_XML_SRC >jetty.xml
#    && sed -e "s/secret/${CRYPTPW}/; s/8443/443/;" <$JETTY_XML_SRC >jetty.xml

# patch webdefaults.xml to support cert mime types
# XXX work in progress, for now we copy our sample file
cp $EXISTCA_HOME/jetty-samples/example-webdefault.xml $JETTY_HOME/etc

# check/fix hostname/network config to match web server name

#$FAKE sh $EXISTCA_HOME/reconfig-net.sh
#if [ $? -ne 0 ]; then
#    logmsg "ERROR - failed to reconfig network"
#    # err out with exit code 5 (network reconfig)
#    exit 5
#fi

# restart exist
#/etc/rc.d/exist restart

