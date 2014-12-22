#!/bin/sh 


INTERFACES=/etc/network/interfaces


# check if interface is already configured for DHCP
get_if_dhcp () {
    if=$1
    grep -q "iface[[:space:]]*${if}.*dhcp" $INTERFACES
}

# create interface configuration for DHCP
set_if_dhcp () {
    if=$1
    # better leave that to a perl script, way too complicated to do in shell..
    return 1
}

# change interface configuration
reconfig_if () {
    if=$1
    ifup $if
}

# rebuild ntpd.conf
reconfig_ntpd () {
    srvs=$*
    file=/etc/ntp.conf
    bak="$file.`mkbackuptimestamp`"
    [ -f "$file" ] && cp -p $file $bak

    for s in $srvs; do
	logmsg "adding NTP server $s"
	SEDOUT="server $s\n"
    done
    sed -e "s/%SERVERDEFS%/$SEDOUT/;" <Debian/sample-ntp.conf >$file
}

# restart ntp daemon
restart_ntpd () {
    # explicitly kill and start rather than "/etc/rc.d/ntpd restart"
    pkill ntpd
    if pgrep -lf ntpd >/dev/null; then
	logmsg "ERROR - ntpd still running"
	return 1
    else
	service ntp start
	return $?
    fi
}

