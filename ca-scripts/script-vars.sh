#!/bin/sh

### utility shell functions come first

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
	*) logmsg "unsupported keysize $ks"; return 1;;
    esac
}

# verify that arg is a positive integer
verify_posint () {
    i=$1
    [[ $i -gt 0 ]] || ( logmsg "expire not positive int $i"; return 1 )
}

# verify cert type
verify_certtype () {
    t=$1
    case "$t" in
	server|client) ;;
	*) logmsg "unsupported certificate type $t"; return 1;;
    esac
}


# PKCS12 export password
#export EXISTCA_EXPORTPASS=export
export EXISTCA_EXPORTPASS=secret

### Common enviroment variables that get passed to easyrsa (easyrsa API)

# basedir for the EasyRSA software.  needed to call easyrsa scripts
export EASYRSA=$EXISTCA_HOME/easyrsa

# set batch mode
export EASYRSA_BATCH=yes

# if "org" add city/country etc to certs.  else use simple common name
export EASYRSA_DN=org

# reset some env vars
export EASYRSA_NS_COMMENT=

# do not parse any kind of easyrsa vars file
export EASYRSA_NO_VARS

# OpenSSL config file, defaults are usually fine
#export EASYRSA_SSL_CONF=$EXISTCA_HOME/data/openssl.cnf


