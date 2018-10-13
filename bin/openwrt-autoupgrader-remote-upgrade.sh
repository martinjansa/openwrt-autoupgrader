#!/bin/bash

printf "OpenWrt-Autoupgrader - Remote upgrade\n"

if [[ "$1" = "" ]]; then printf "Usage: openwrt-autoupgrader.sh user@host\nWhere user@host is the user name (typically root) that should perform the upgrade on the specified host. We should be able to connect from this machine to the specified remote account.\n"; exit 1; fi

ROUTER_USERNAME="`echo \"$1\" | awk -F \"@\" '{print $1}'`"
ROUTER_HOSTNAME="`echo \"$1\" | awk -F \"@\" '{print $2}'`"

# path to the deployed upgrade script
REMOTE_AUTOUPGRADER_SCRIPT_PATH="/usr/local/sbin/openwrt-autoupgrader.sh"

printf "Checking the availability of the router $ROUTER_HOSTNAME via ping... "

# ping the machine one and check the result
ping -c 1 $ROUTER_HOSTNAME > /dev/null 2>&1
PING_RESULT=$?

# if machine is not available, exit with error
if [[ "$PING_RESULT" = "0" ]]; then printf "OK.\n"; else printf "Error: ping to $ROUTER_HOSTNAME failed with error $PING_RESULT.\n"; exit 1; fi


printf "Performing firmware upgrade of the $ROUTER_HOSTNAME..."

FIRMWARE_UPGRADE_LOG_FILE="/tmp/openwrt-autoupgrader-remote-upgrade-ssh.log"

# run the upgrade remotely
(ssh $ROUTER_USERNAME@$ROUTER_HOSTNAME $REMOTE_AUTOUPGRADER_SCRIPT_PATH upgrade_firmware) | tee "$FIRMWARE_UPGRADE_LOG_FILE"

# if the upgrade was started
REMOTE_UPGRADE_DONE=`grep "WARNING: Performing the firmware upgrade from" "$FIRMWARE_UPGRADE_LOG_FILE" | wc -l`
if [[ $REMOTE_UPGRADE_DONE = 1 ]]; then

    printf "INFO: The firmware upgrade is being done on the router $ROUTER_HOSTNAME.\n"

    printf "Waiting for the upgrade to finish: "

    ROUTER_RUNNING="0"

    # wait for 10s to make sure the upgrade has started
    for i in $(seq 1 10); do sleep 1s; printf "-"; done

    # wait for 1 min for the router IP to be reachable again
    for i in $(seq 1 120); do 
        sleep 1s; 
        # ping the machine one and check the result
        ping -i 0.2 -c 1 -t 1 -W 1 $ROUTER_HOSTNAME > /dev/null 2>&1
        PING_RESULT=$?
        if [[ "$PING_RESULT" = "0" ]]; then printf "..X"; ROUTER_RUNNING="1"; break; fi
        printf "..."; 
    done

    # wait for annother 10s to make sure the ssh service is up and running on the router
    for i in $(seq 1 10); do sleep 1s; printf "-"; done

    # if the router is running
    if [[ "$ROUTER_RUNNING" = "1" ]]; then printf "OK.\nFirmware successfully upgraded, router is up and running.\n"; else printf "Error.\nError: Router did not boot up after the firmware. Please see the https://github.com/cellux/openwrt-upgrade howto.\n"; exit 1; fi

else 
    printf "The firmware upgrade not started on the remote host.\n"

fi

printf "TODO: Remote packages upgrade has not been implemented yet.\n"

exit 1
