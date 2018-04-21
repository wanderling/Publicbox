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
echo "Publicbox is a 'internet-and-pbx-in-a-box' and is made to be a communications service were there is none."
echo "Please use responsibly!"
echo "Press any key to continue."
read -n 1 
clear

if [[ $1 ]]
then
	clear
	echo "Starting install..."
	sleep 3
	clear
else
	echo "Useage: /bin/bash install.sh <default|board>"
	exit 0
fi
	
#Import PublicBox conf
CURRENT_CONF=publicbox/conf/publicbox.conf
scriptfile="$(readlink -f $0)"
CURRENT_DIR="$(dirname ${scriptfile})"

if [[ -f  "$CURRENT_DIR"/$CURRENT_CONF ]]
then
	. $CURRENT_CONF 2> /dev/null
else
	echo "PublicBox config is not in its normal directory"
	exit 0
fi

#Detirmine what architecture we are installing to
ARCH=$(uname -m)

if [ $ARCH = "armv7l" ]
then
	clear
	echo "You seem to be on a Raspberry Pi."
	echo "Have you performed the Raspberry Pi configuration utility?"
	read -r -p "[Yes/No] " response
	echo
	if [[ "$response" =~ ^([nN][oO]|[nN])+$ ]]
	then
		echo "Please complete the Raspberry Pi configuration first. Then rerun this install script."
		exit 0
	fi
else
	echo "You seem to be running an $ARCH machine."
	echo "Would you like to set the device locale?"
	read -r -p "[Yes/No] " response
	echo
	if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
	then
		dpkg-reconfigure locales
	fi
	echo "Would you like to set the current timezone?"
	read -r -p "[Yes/No] " response
	echo
	if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
	then
		dpkg-reconfigure tzdata
	fi
	echo "Would you like to set the keyboard locale?"
	read -r -p "[Yes/No] " response
	echo
	if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
	then
		eval "sudo -u pi lxinput"
	fi
fi

#Installation customization
echo "You will be asked some questions in order to customize and properly prepare"
echo "your installation of Publicbox to your device."
echo
echo "Would you like to leave the 75-persistent-net-generator.rules file alone or use"
echo "the modified version that ties your wifi adapter to your adapter name? This is"
echo "helpful if you have multiple adapters on your machine and need PublicBox to use a"
echo "specific adapter."
echo "Example: Wi-fi adapter #1 --> wlan0 and Wi-fi adapter #2 --> wlan1 always"
echo "[L]eave unchanged or [C]hange"
unset ANSWER
while [ -z ${ANSWER} ]
do
	read ANSWER
done
if [[ $ANSWER = "C" || $ANSWER = "c" || $ANSWER = "Change" || $ANSWER = "change" || $ANSWER = "CHANGE" ]]
then
	cp -f "$CURRENT_DIR"/custom_rules/75-persistent-net-generator.rules /lib/udev/rules.d/75-persistent-net-generator.rules
	chown root:root /lib/udev/rules.d/75-persistent-net-generator.rules
	chmod 755 /lib/udev/rules.d/75-persistent-net-generator.rules
fi

clear
echo "Would you like to place commonly used shortcuts on the desktop? This will also"
echo "remove your existing wallpaper. You can change this back anytime."
echo "Examples: Start/Stop PublicBox, Start/Stop Asterisk etc."
echo "[L]eave unchanged or [C]hange"
unset ANSWER
while [ -z ${ANSWER} ]
do
	read ANSWER
done
if [[ $ANSWER = "C" || $ANSWER = "c" || $ANSWER = "Change" || $ANSWER = "change" || $ANSWER = "CHANGE" ]]
then
	cp -rv "$CURRENT_DIR"/desktop_icons/* /home/pi/Desktop
	cp -f "$CURRENT_DIR"/custom_rules/desktop-items-0.conf /home/pi/.config/pcmanfm/LXDE-pi/desktop-items-0.conf
	chown pi:pi /home/pi/.config/pcmanfm/LXDE-pi/desktop-items-0.conf
	chmod 755 /home/pi/.config/pcmanfm/LXDE-pi/desktop-items-0.conf
fi

#Install dependencies
unset SURE
echo -n "Some dependencies may be missing. Would you like to install them? (Y/n): "
read SURE
if [[ $SURE = "Y" || $SURE = "y" || $SURE = "" || $SURE = "yes" || $SURE = "Yes" ]]
then
    PKGSTOINSTALL="hostapd lighttpd dnsmasq iw thunar"
    apt-get update
    apt-get upgrade -y
    
    #Check for dependencies 
    for i in $PKGSTOINSTALL ; do
        dpkg-query -W -f='${Package}\n' | grep ^$i$ > /dev/null
        if [ $? != 0 ] ; then
            echo "Installing $i..."
            aptitude install $i -y
        fi
    done  
fi
/etc/init.d/lighttpd stop
update-rc.d lighttpd remove
/etc/init.d/dnsmasq stop
update-rc.d dnsmasq remove
/etc/init.d/hostapd stop
update-rc.d hostapd remove
    
#Libreoffice is a pain and gets in the way while setting up. So I made an option to remove it completely.
unset SURE
echo "LibreOffice is a pain and gets in the way while setting up."
echo "So I made an option to remove it completely."
echo "You do not have to uninstall LibreOffice to use Publicbox!" 
echo -n "Would you like to remove LibreOffice? (Y/n): "
read SURE
if [[ $SURE = "Y" || $SURE = "y" || $SURE = "" || $SURE = "yes" || $SURE = "Yes" ]]
then
	apt-get purge -y libreoffice*
	clear
fi

#begin setting up publicbox's home dir
if [[ ! -d /opt ]]
then
	mkdir -p /opt
fi

#Copy files
cp -rv "$CURRENT_DIR"/publicbox /opt
chmod -R 755 /opt/publicbox

#cp -f "$CURRENT_DIR"/custom_rules/70-persistent-net.rules /etc/udev/rules.d/70-persistent-net.rules
#chmod 755 /etc/udev/rules.d/70-persistent-net.rules

cp -f "$CURRENT_DIR"/custom_rules/sysctl.conf /etc/sysctl.conf
chmod 755 /etc/sysctl.conf

cp -f "$CURRENT_DIR"/custom_rules/ipv6.conf /etc/modprobe.d/ipv6.conf
chmod 755 /etc/modprobe.d/ipv6.conf

cp -f "$CURRENT_DIR"/custom_rules/panel /home/pi/.config/lxpanel/LXDE-pi/panels/panel
chown pi:pi /home/pi/.config/lxpanel/LXDE-pi/panels/panel
chmod 755 /home/pi/.config/lxpanel/LXDE-pi/panels/panel

versionId=$( cat /etc/os-release | grep -i "VERSION_ID" | awk -F'"' "{print $2}")
if [ $versionId -eq "8" ]
then
	#cp -f "$CURRENT_DIR"/custom_rules/interfaces /etc/network/interfaces
	#chown root:root /etc/network/interfaces
	#chmod 755 /etc/network/interfaces

	#cp -f "$CURRENT_DIR"/custom_rules/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf
	#chown root:root /etc/wpa_supplicant/wpa_supplicant.conf
	#chmod 755 /etc/wpa_supplicant/wpa_supplicant.conf
fi

if [[ ! -d /home/pi/.config/Thunar/ ]]
then
	mkdir -p /home/pi/.config/Thunar/
	chown pi:pi /home/pi/.config/Thunar/
fi
cp -f "$CURRENT_DIR"/custom_rules/uca.xml /home/pi/.config/Thunar/uca.xml
chown pi:pi /home/pi/.config/Thunar/uca.xml
chmod 755 /home/pi/.config/Thunar/uca.xml	

echo "Finished copying files..."

echo "$NET.$IP_SHORT publicbox.lan">>/etc/hosts
echo "$NET.$IP_SHORT publicbox">>/etc/hosts

sed 's:DROOPY_USE_USER="no":DROOPY_USE_USER="yes":' -i /opt/publicbox/conf/publicbox.conf

if [[ -d /etc/init.d/ ]]
then
	ln -s /opt/publicbox/init.d/publicbox /etc/init.d/publicbox
	echo "To make PublicBox start at boot run: update-rc.d publicbox defaults"
#	systemctl enable publicbox #This enables PublicBox at start up... could be useful for Live
else
	#link between opt and etc/pb
	ln -s /opt/publicbox/init.d/publicbox.service /etc/systemd/system/publicbox.service
	echo "To make PublicBox start at boot run: systemctl enable publicbox"
fi



#install publicbox with the given option
case "$1" in
	default)
		sudo bash /opt/publicbox/bin/install_publicbox.sh /opt/publicbox/conf/publicbox.conf part2
		;;
	board)
		sudo bash /opt/publicbox/bin/install_publicbox.sh /opt/publicbox/conf/publicbox.conf imageboard
		echo "############################################################################"
		echo "#Edit /opt/publicbox/share/board/config.pl and change ADMIN_PASS and SECRET#"
		echo "############################################################################"
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
	
	HEADER_NAME=$(uname -r)    	
	apt-get update
	apt-get upgrade -y
	apt-get -y install mysql-workbench
	apt-get -y install asterisk-voicemail-odbcstorage
	apt-get -y install asterisk-voicemail
	apt-get -y install asterisk-ooh323
	apt-get -y install asterisk-mp3
	apt-get -y install asterisk-moh-opsound-wav 
	apt-get -y install asterisk-moh-opsound-gsm
	apt-get -y install asterisk-moh-opsound-g722
	apt-get -y install asterisk-doc
	apt-get -y install asterisk-modules
	apt-get -y install asterisk-core-sounds-en-gsm
	apt-get -y install asterisk-core-sounds-en-wav
	apt-get -y install asterisk-core-sounds-en-g722
	apt-get -y install asterisk-core-sounds-en
	apt-get -y install asterisk-config
	apt-get -y install subversion
	apt-get -y install libmyodbc
	apt-get -y install libspandsp-dev
	apt-get -y install libsrtp0-dev
	apt-get -y install libneon27-dev
	apt-get -y install libical-dev
	apt-get -y install libcurl4-openssl-dev
	apt-get -y install libvorbis-dev
	apt-get -y install libogg-dev
	apt-get -y install libasound2-dev
	apt-get -y install uuid-dev
	apt-get -y install uuid
	apt-get -y install unixodbc-dev
	apt-get -y install autoconf
	apt-get -y install libtool
	apt-get -y install automake
	apt-get -y install pkg-config
	apt-get -y install libsqlite3-dev
	apt-get -y install sqlite3
	apt-get -y install libnewt-dev
	apt-get -y install libxml2-dev
	apt-get -y install mpg123
	apt-get -y install libmysqlclient-dev
	apt-get -y install libssl-dev
	apt-get -y install libncurses5-dev
	apt-get -y install build-essential
	apt-get -y install linux-headers-$HEADER_NAME
	apt-get -y install openssh-server
	apt-get -y install mysql-server
	apt-get -y install mysql-client
	apt-get -y install bison
	apt-get -y install flex
	apt-get -y install php5-cgi
	apt-get -y install php5
	apt-get -y install php5-curl
	apt-get -y install php5-cli
	apt-get -y install php5-mysql
	apt-get -y install php-pear
	apt-get -y install php5-gd
	apt-get -y install curl
	apt-get -y install sox

	/etc/init.d/asterisk stop
	update-rc.d asterisk remove

	ATT="with Asterisk PBX"

	echo "Asterisk PBX has been installed..."
	echo 
	echo "Press any key to continue."
	read -n 1
	clear
else
	clear
	echo "Cancelling Asterisk PBX install..."

	ATT="without Asterisk PBX"

	sleep 1
	clear
fi

clear
RED='\e[31;5m'
NC='\e[0m'
echo
echo -e "${RED} Publicbox $ATT has finished installing!!!${NC}"
echo
echo "Please reboot this computer at your earliest convienence."
echo
echo "Thank you. I sincerely hope you enjoy Publicbox!"
echo
echo "For any bugs or suggestions, please feel free to drop me a"
echo "line at danielsroseman@gmail.com"
exit 0
