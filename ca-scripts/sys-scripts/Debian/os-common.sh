#!/bin/sh 

# Debian network config file
INTERFACES=/etc/network/interfaces

# vars for OpenVPN on Debian
OPENVPN_DIR=/etc/openvpn
OPENVPN_USER=nobody
OPENVPN_GROUP=nogroup
OPENVPN_CHROOT=


### functions for installation and setup

install_pkg () {
    pkg=$1
    case "$pkg" in
	java)
	    pkg=default-jre-headless
	    ;;
	*) :;;
    esac
    apt-get install $pkg
}


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
    # keep backup of original config file when run the first time
    [ -f "$file" -a ! -f "$file.ORIG" ] && cp -p $file $file.ORIG
    [ $? -ne 0 ] && err=1
    # backup config file everytime we attempt to modify it
    bak="$file.`mkbackuptimestamp`"
    [ -f "$file" ] && cp -p $file $bak && ln -sf $bak $file.LAST
    [ $? -ne 0 ] && err=1

    for s in $srvs; do
	logmsg "adding NTP server $s"
	SEDOUT="server $s\n"
    done
    sed -e "s/%SERVERDEFS%/$SEDOUT/;" <Debian/sample-ntp.conf >$file
    [ $? -ne 0 ] && err=1

    if [ $err -ne 0 ]; then
	logmsg "failed to reconfig ntpd, trying to restore backup"
	cp -p $file.LAST $file
	return 1
    fi

    return 0
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

