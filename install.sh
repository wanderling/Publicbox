#!/bin/bash
#=======================================================================
#
#	FILE:  install.sh
# 
#	USAGE:  ./install.sh 
# 
#	DESCRIPTION:  Install file for PublicBox. Created from PirateBox source.
# 
#	OPTIONS:  ./install.sh <default|board> <optional: USB path>
#
#	REQUIREMENTS:  ---
#	BUGS:  Link from install
#	NOTES:  ---
#	ORIGINAL AUTHOR: Cale 'TerrorByte' Black, cablack@rams.colostate.edu
#	COMPANY:  ---
#	CREATED: 02.02.2013 19:50:34 MST
#	FUTHER MODIFIED: 06.06.2017 (D.R.)
#	REVISION:  a0.1
#	LICENCE: (c) Cale Black, 2013 GPL-3
#	ADDITIONAL LICENSE: (C) Daniel Roseman, 2017 GPL-3
#=======================================================================
#Must be root

if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root" #1>&2
        exit 0
fi

echo "This script is designed only for Rasbian x86 or ARM (Raspberry Pi 3 is recommended!) at this time."
echo "Press any key to continue."
read -n 1 
clear

echo "Have you performed the Raspberry Pi configuration utility?"
read -r -p "[Yes/No] " response
echo
if [[ "$response" =~ ^([nN][oO]|[nN])+$ ]]; then
	echo "Please complete the Raspberry Pi configuration first."
	rc_gui && exit 0
fi

echo "Would you like to set the current timezone?"
read -r -p "[Yes/No] " response
echo
if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
	dpkg-reconfigure tzdata
fi

echo "Would you like to set the locale?"
read -r -p "[Yes/No] " response
echo
if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
	eval "sudo dpkg-reconfigure locales"
fi

echo "Would you like to set the keyboard locale?"
read -r -p "[Yes/No] " response
echo
if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
	eval "sudo -u pi lxinput"
fi
	
#Import PublicBox conf
CURRENT_CONF=publicbox/conf/publicbox.conf
scriptfile="$(readlink -f $0)"
CURRENT_DIR="$(dirname ${scriptfile})"

if [[ $1 ]]; then
	echo "Installing..."
else
	echo "Useage: /bin/bash install.sh <default|board>"
	exit 0
fi

if [[ -f  "$CURRENT_DIR"/$CURRENT_CONF ]]; then
	. $CURRENT_CONF 2> /dev/null
else
	echo "PublicBox config is not in its normal directory"
	exit 0
fi

#begin setting up publicbox's home dir
if [[ ! -d /opt ]]; then
	mkdir -p /opt
fi

cp -rv "$CURRENT_DIR"/publicbox /opt &> /dev/null
cp -rv "$CURRENT_DIR"/desktop_icons/* /home/pi/Desktop &> /dev/null

cp -f "$CURRENT_DIR"/custom_rules/75-persistent-net-generator.rules /lib/udev/rules.d/75-persistent-net-generator.rules
chmod 755 /lib/udev/rules.d/75-persistent-net-generator.rules

cp -f "$CURRENT_DIR"/custom_rules/70-persistent-net.rules /etc/udev/rules.d/70-persistent-net.rules
chmod 755 /etc/udev/rules.d/70-persistent-net.rules

cp -f "$CURRENT_DIR"/custom_rules/sysctl.conf /etc/sysctl.conf
chmod 755 /etc/sysctl.conf

cp -f "$CURRENT_DIR"/custom_rules/ipv6.conf /etc/modprobe.d/ipv6.conf
chmod 755 /etc/modprobe.d/ipv6.conf

cp -f "$CURRENT_DIR"/custom_rules/panel /home/pi/.config/lxpanel/LXDE-pi/panels/panel
chown pi:pi /home/pi/.config/lxpanel/LXDE-pi/panels/panel
chmod 755 /home/pi/.config/lxpanel/LXDE-pi/panels/panel

cp -f "$CURRENT_DIR"/custom_rules/desktop-items-0.conf /home/pi/.config/pcmanfm/LXDE-pi/desktop-items-0.conf
chown pi:pi /home/pi/.config/pcmanfm/LXDE-pi/desktop-items-0.conf
chmod 755 /home/pi/.config/pcmanfm/LXDE-pi/desktop-items-0.conf

cp -f "$CURRENT_DIR"/custom_rules/interfaces /etc/network/interfaces
chown root:root /etc/network/interfaces
chmod 755 /etc/network/interfaces

cp -f "$CURRENT_DIR"/custom_rules/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf
chown root:root /etc/wpa_supplicant/wpa_supplicant.conf
chmod 755 /etc/wpa_supplicant/wpa_supplicant.conf

echo "Finished copying files..."

echo "$NET.$IP_SHORT publicbox.lan">>/etc/hosts
echo "$NET.$IP_SHORT publicbox">>/etc/hosts

sed 's:DROOPY_USE_USER="no":DROOPY_USE_USER="yes":' -i /opt/publicbox/conf/publicbox.conf

if [[ -d /etc/init.d/ ]]; then
	ln -s /opt/publicbox/init.d/publicbox /etc/init.d/publicbox
	echo "To make PublicBox start at boot run: update-rc.d publicbox defaults"
#	systemctl enable publicbox #This enables PublicBox at start up... could be useful for Live
else
	#link between opt and etc/pb
	ln -s /opt/publicbox/init.d/publicbox.service /etc/systemd/system/publicbox.service
	echo "To make PublicBox start at boot run: systemctl enable publicbox"
fi

#install dependencies
PKGSTOINSTALL="hostapd lighttpd dnsmasq iw thunar"
if [ "$PKGSTOINSTALL" != "" ]; then
	echo -n "Some dependencies may missing. Would you like to install them? (Y/n): "
	read SURE
	if [[ $SURE = "Y" || $SURE = "y" || $SURE = "" || $SURE = "yes" || $SURE = "Yes" ]]; then
		apt-get update
		apt-get upgrade -y
		apt-get install -y $PKGSTOINSTALL
		/etc/init.d/lighttpd stop
		update-rc.d lighttpd remove
		/etc/init.d/dnsmasq stop
		update-rc.d dnsmasq remove
		/etc/init.d/hostapd stop
		update-rc.d hostapd remove
		
		mkdir /home/pi/.config/Thunar/
		chown pi:pi /home/pi/.config/Thunar/
		cp -f "$CURRENT_DIR"/custom_rules/uca.xml /home/pi/.config/Thunar/uca.xml
		chown pi:pi /home/pi/.config/Thunar/uca.xml
		chmod 755 /home/pi/.config/Thunar/uca.xml
		
	fi

	echo -n "Would you like to remove LibreOffice? (Y/n): "
	read SURE
	if [[ $SURE = "Y" || $SURE = "y" || $SURE = "" || $SURE = "yes" || $SURE = "Yes" ]]; then
	apt-get purge -y libreoffice*
	fi
fi

#install publicbox with the given option
case "$1" in
	default)
		/opt/publicbox/bin/install_publicbox.sh /opt/publicbox/conf/publicbox.conf part2
		;;
	board)
		/opt/publicbox/bin/install_publicbox.sh /opt/publicbox/conf/publicbox.conf imageboard
		echo "############################################################################"
		echo "#Edit /opt/publicbox/share/board/config.pl and change ADMIN_PASS and SECRET#"
		echo "############################################################################"
		exit 0
		;;
	*)
		echo "$1 is not an option. Useage: /bin/bash install.sh <default|board>"
		exit 0
		;;
esac

echo "##############################"
echo "#PublicBox has been installed#"
echo "##############################"
echo ""
echo "Use: sudo service publicbox <start|stop>"
echo "or for systemd systems Use: sudo systemctl <start|stop|restart> publicbox"
echo
echo "Press any key to continue."
read -n 1
clear
echo "Please press 'Enter' to install Asterisk PBX, any other key to cancel."
IFS=

read -n 1 key
if [ "$key" = "" ]; then
	clear
	echo "Installing Asterisk PBX..."
	sleep 3
	clear
	apt-get install -y asterisk

	#SUDO_CHECK=$(id -Gn "asterisk"|grep -c "sudo")
	#if [ "$SUDO_CHECK" = 0 ]; then
	#	usermod -a -G sudo asterisk
	#fi
	
	apt-get install -y asterisk-config
	apt-get install -y asterisk-core-sounds-en
	apt-get install -y asterisk-core-sounds-en-g722
	apt-get install -y asterisk-core-sounds-en-wav
	apt-get install -y asterisk-core-sounds-en-gsm
	apt-get install -y asterisk-doc
	apt-get install -y asterisk-modules
	apt-get install -y asterisk-moh-opsound-g722
	apt-get install -y asterisk-moh-opsound-gsm
	apt-get install -y asterisk-moh-opsound-wav
	apt-get install -y asterisk-mp3
	apt-get install -y asterisk-ooh323
	apt-get install -y asterisk-voicemail
	apt-get install -y asterisk-voicemail-odbcstorage
	apt-get install -y mysql-workbench

	/etc/init.d/asterisk stop
	update-rc.d asterisk remove

	echo "Asterisk PBX has been installed..."
	echo 
	echo "Press any key to continue."
	read -n 1
	clear
else
	clear
	echo "Cancelling Asterisk PBX install..."
	sleep 1
	clear
fi
clear
echo "Please press 'Enter' to install FreePBX prerequisites, any other key to cancel."

IFS=

read -n 1 key
if [ "$key" = "" ]; then
	clear
	echo "Installing FreePBX prerequisites..."
	sleep 3
	clear
	HEADER_NAME=$`uname -r`
	apt-get install -y build-essential
	apt-get install -y linux-headers-$HEADER_NAME
	apt-get install -y openssh-server
	apt-get install -y mysql-server
	apt-get install -y mysql-client
	apt-get install -y bison
	apt-get install -y flex
	apt-get install -y php5-cgi
	apt-get install -y php5
	apt-get install -y php5-curl
	apt-get install -y php5-cli
	apt-get install -y php5-mysql
	apt-get install -y php-pear
	apt-get install -y php5-gd
	apt-get install -y curl
	apt-get install -y sox
	apt-get install -y libncurses5-dev
	apt-get install -y libssl-dev
	apt-get install -y libmysqlclient-dev
	apt-get install -y mpg123
	apt-get install -y libxml2-dev
	apt-get install -y libnewt-dev
	apt-get install -y sqlite3
	apt-get install -y libsqlite3-dev
	apt-get install -y pkg-config
	apt-get install -y automake
	apt-get install -y libtool
	apt-get install -y autoconf
	apt-get install -y git
	apt-get install -y unixodbc-dev
	apt-get install -y uuid
	apt-get install -y uuid-dev
	apt-get install -y libasound2-dev
	apt-get install -y libogg-dev
	apt-get install -y libvorbis-dev
	apt-get install -y libcurl4-openssl-dev
	apt-get install -y libical-dev
	apt-get install -y libneon27-dev
	apt-get install -y libsrtp0-dev
	apt-get install -y libspandsp-dev
	apt-get install -y sudo
	apt-get install -y libmyodbc
	apt-get install -y subversion
	clear
	RED='\e[31;5m'
	NC='\e[0m'
	echo -e "${RED}FreePBX has not yet been installed!!!${NC}"
	echo
	echo "This computer need to be rebooted first."
	echo
	echo "When the computer has finished rebooting, run 'sudo ./freepbx_install.sh'."
	echo "This will continue the install."
	echo
	echo "Press any key to reboot."
	read -n 1
	clear
	reboot
	exit 0
else
	clear
	echo "Cancelling FreePBX prerequisites install..."
	sleep 1
	clear
	exit 0
fi
exit 0