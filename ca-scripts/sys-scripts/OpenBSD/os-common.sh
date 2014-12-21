#!/bin/sh 

# check if interface is already configured for DHCP
get_if_dhcp () {
    if=$1
    file=/etc/hostname.$if
    if [ ! -f "$file" ]; then
	logmsg "file $file not found"
	return 2
    else
	grep -q "dhcp" $file
    fi
}

# create interface configuration for DHCP
set_if_dhcp () {
    if=$1
    file=/etc/hostname.$if
    bak="$file.`mkbackuptimestamp`"
    [ -f "$file" ] && cp -p $file $bak
    echo "dhcp" >$file
}

# change interface configuration
reconfig_if () {
    if=$1
    sh /etc/netstart $if
}

# rebuild ntpd.conf and restart ntp daemon
reconfig_ntpd () {
    srvs=$*
    file=/etc/ntpd.conf
    bak="$file.`mkbackuptimestamp`"
    [ -f "$file" ] && cp -p $file $bak

    echo "listen on *" >$file
    for s in $srvs; do
	logmsg "adding NTP server $s"
	echo "server $s" >>$file
    done

    # explicitly kill and start rather than "/etc/rc.d/ntpd restart"
    pkill ntpd
    if pgrep -lf ntpd >/dev/null; then
	logmsg "ERROR - ntpd still running"
	return 1
    else
	/etc/rc.d/ntpd start
	return $?
    fi
}

