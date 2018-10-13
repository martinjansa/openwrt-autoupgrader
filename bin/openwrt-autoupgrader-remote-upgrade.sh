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

# if failed, terminate
SSH_RESULT=$?
if [[ "$SSH_RESULT" = "0" ]]; then printf "SSH succeeded.\n"; else printf "Error: SSH failed with error $SSH_RESULT.\n"; exit 1; fi

# if the upgrade was started
REMOTE_UPGRADE_DONE=`grep "WARNING: Performing the firmware upgrade from" "$FIRMWARE_UPGRADE_LOG_FILE" | wc -l`
if [[ $REMOTE_UPGRADE_DONE = 1 ]]; then

    printf "INFO: The firmware upgrade is being done on the router $ROUTER_HOSTNAME.\n"

    printf "TODO: Waiting for the upgrade to finish has not been implemented yet.\n"

else 
    printf "The firmware upgrade not started on the remote host.\n"

fi

printf "TODO: Remote packages upgrade has not been implemented yet.\n"

exit 1
