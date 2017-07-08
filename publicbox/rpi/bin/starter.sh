#!/bin/sh
# Try to setup WiFi and if it succeeds, start the PublicBox

## Default 
WIFI_DEVICE="wlan0"

WIFI_CONFIG_PATH="/boot/wifi_card.conf"

if test -e "${WIFI_CONFIG_PATH}" ; then
    echo "Found wifi card config"
    WIFI_DEVICE=$( head -n 1 "${WIFI_CONFIG_PATH}" | tr -d '\n'  )
fi


if [ "${INTERFACE}" = "${WIFI_DEVICE}" ] ; then
    /bin/sh -c /opt/publicbox/rpi/bin/wifi_detect.sh && /usr/bin/systemctl start publicbox
fi
exit 0
