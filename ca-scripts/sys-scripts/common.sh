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

# determine OS, release and distribution that we're running oo
determine_osdir () {
    os_type=`uname -s`
    #os_release=`uname -r`
    #os_host=`uname -n`

    case "$os_type" in
	OpenBSD)
	    return OpenBSD
	    ;;
	Linux)
	    # determine Linux distribution
	    [ -f /etc/debian_version ] && return Debian
	    ;;
    esac

    logmsg "OS $os_type yet unsupported"
    return ""
}

# create timestamp string fragment for backup file names
mkbackuptimestamp () {
    echo "save.`date '+%F-%H:%M:%S'`"
}

