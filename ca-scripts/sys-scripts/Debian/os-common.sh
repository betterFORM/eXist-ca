#!/bin/sh 

# Debian network config file
INTERFACES=/etc/network/interfaces


### functions for network configuration

# check if interface is already configured for DHCP
get_if_dhcp () {
    if=$1
    grep -q "iface[[:space:]]*${if}.*dhcp" $INTERFACES
}

# create interface configuration for DHCP
set_if_dhcp () {
    if=$1
    file=$INTERFACES
    bak="$file.`mkbackuptimestamp`"
    [ -f "$file" ] && cp -p $file $bak
    # this is a gross hack that more or less works in common cases only
    # better leave that to a perl script, way too complicated to do in shell
    sed -e '/static/dhcp/;' <$bak >$file
}

# change interface configuration
reconfig_if () {
    if=$1
    ifup $if
}


### functions for NTP configuration

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


### functions for OpenVPN configuration

# restart openvpn daemon
restart_openvpn () {
    # explicitly kill and start rather than "/etc/rc.d/openvpn restart"
    pkill openvpn
    if pgrep -lf openvpn >/dev/null; then
	logmsg "ERROR - openvpn still running"
	return 1
    else
	service openvpn start
	return $?
    fi
}

