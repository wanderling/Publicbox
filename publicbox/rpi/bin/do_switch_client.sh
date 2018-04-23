#!/bin/sh

# Wrapper script for the steps to enable wifi client

systemctl stop publicbox
if /opt/publicbox/rpi/bin/run_client.sh ; then
    echo "Started Wifi client sucessfully!"
    exit 0
else
    echo "Error while starting wifi client, restarting publicbox"
    systemctl start publicbox
    exit 1
fi
exit 1 
