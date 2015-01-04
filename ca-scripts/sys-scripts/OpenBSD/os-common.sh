#!/bin/sh 

# vars for OpenVPN on OpenBSD
OPENVPN_DIR=/etc/openvpn
OPENVPN_USER=_openvpn
OPENVPN_GROUP=_openvpn
OPENVPN_CHROOT=/var/empty


### functions for installation and setup

install_pkg () {
    pkg=$1
    case "$pkg" in
	java)
	    pkg=jre
	    ;;
	*) :;;
    esac
    pkg_add $pkg
}


### functions for network configuration

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


### functions for NTP configuration

# rebuild ntpd.conf
reconfig_ntpd () {
    srvs=$*
    err=0
    file=/etc/ntpd.conf
    # keep backup of original config file when run the first time
    [ -f "$file" -a ! -f "$file.ORIG" ] && cp -p $file $file.ORIG
    [ $? -ne 0 ] && err=1
    # backup config file everytime we attempt to modify it
    bak="$file.`mkbackuptimestamp`"
    [ -f "$file" ] && cp -p $file $bak && ln -sf $bak $file.LAST
    [ $? -ne 0 ] && err=1

    echo "listen on *" >$file
    for s in $srvs; do
	logmsg "adding NTP server $s"
	echo "server $s" >>$file
    done
    [ $? -ne 0 ] && err=1

    ntpd -nf $file || err=1

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
	/etc/rc.d/ntpd start
	return $?
    fi
}


### functions for OpenVPN configuration

# restart OpenVPN daemon
restart_openvpn () {
    # explicitly kill and start rather than "/etc/rc.d/openvpn restart"
    pkill openvpn
    if pgrep -lf openvpn >/dev/null; then
	logmsg "ERROR - openvpn still running"
	return 1
    else
	/etc/rc.d/openvpn start
	return $?
    fi
}

