#!/bin/sh


export EXISTCA_EXPORTPASS=export

### Common enviroment variables that get passed to easyrsa

# basedir for the EasyRSA software.  needed to call easyrsa scripts
export EASYRSA=$EXISTCA_HOME/resources/easyrsa3
#export EASYRSA=$EXISTCA_HOME/easyrsa3

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
#export EASYRSA_SSL_CONF=$EXISTCA_HOME/data/openssl.cnf


checkenv () {
    TMPENV=`mktemp` || exit 1
    enverr=0
    env >$TMPENV
    for e in $*; do
	if ! grep -q "$e" $TMPENV; then
	    echo "required env var \"$e\" is undefined"
	    enverr=1
	fi
    done
    rm -f $TMPENV
    return $enverr
}
