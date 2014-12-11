#!/bin/sh


export EXISTCA_EXPORTPASS=export

### Common enviroment variables that get passed to easyrsa (easyrsa API)

# basedir for the EasyRSA software.  needed to call easyrsa scripts
export EASYRSA=$EXISTCA_HOME/../resources/easyrsa3
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
export EASYRSA_NO_VARS

# OpenSSL config file, defaults are usually fine
#export EASYRSA_SSL_CONF=$EXISTCA_HOME/data/openssl.cnf


### utility shell functions

# log a string to stdout and/or syslog
logmsg () {
    echo $*
    [ -x /usr/bin/logger ] && logger -t eXistCA "$*"
}

# check all passed variables are defined as env vars, else complain
checkenv () {
    TMPENV=`mktemp tmp.XXXXXXXXXX` || exit 1
    enverr=0
    env >$TMPENV
    for e in $*; do
	if ! grep -q "$e" $TMPENV; then
	    logmsg "required env var \"$e\" is undefined"
	    enverr=1
	fi
    done
    rm -f $TMPENV
    return $enverr
}

# verify valid RSA keysize (key sizes that we support)
verify_rsakeysize () {
    ks=$1
    case "$ks" in
	1024|2048|4096|8192|16384) ;;
	*) logmsg unsupported keysize $ks; return 1;;
    esac
}

# verify expire is a positive integer
verify_expire () {
    [[ $1 -gt 0 ]] || ( logmsg expire not positive int $1; return 1 )
}

