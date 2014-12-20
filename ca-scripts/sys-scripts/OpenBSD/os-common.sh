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

