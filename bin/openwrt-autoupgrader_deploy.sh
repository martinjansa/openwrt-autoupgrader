#!/bin/bash

# configuration file path
CFG_FILE=config/private/deploy

# source (git repo) and destination (router) paths of the deployed files
AU_CFG_FILE_NAME=openwrt-autoupgrader
AU_CFG_FILE_SOURCE_DIR=config/private
AU_CFG_FILE_DEST_DIR=/usr/local/etc

AU_SCRIPT_FILE_NAME=openwrt-autoupgrader.sh
AU_SCRIPT_FILE_SOURCE_DIR=bin
AU_SCRIPT_FILE_DEST_DIR=/usr/local/sbin

# load the configuration
printf "Loading the configuration from file $CFG_FILE...\n"

# configure the separator
IFS="="

# initialize the default values
TARGET_ROUTER_IP=""
TARGET_ROUTER_USERNAME="root"

# parse the config file
while read -r name value
do
    if [[ "$name" = "target_router_ip"       ]]; then TARGET_ROUTER_IP="${value//\"/}";       fi
    if [[ "$name" = "target_router_username" ]]; then TARGET_ROUTER_USERNAME="${value//\"/}"; fi
done < $CFG_FILE

# dump the loaded configuration
printf "Deploy configuration:\n"
printf "\ttarget router IP:       $TARGET_ROUTER_IP\n"
printf "\ttarget router username: $TARGET_ROUTER_USERNAME\n"


# DEPLOYMENT

function deploy_file () {

    TARGET_USERNAME="$1"
    TARGET_HOSTNAME="$2"
    FILE_NAME="$3"
    SOURCE_DIR="$4"
    DEST_DIR="$5"
    
    printf "Deploying file $SOURCE_DIR/$FILE_NAME to $TARGET_USERNAME@$TARGET_HOSTNAME:$DEST_DIR/$FILE_NAME... "

    ssh "$TARGET_USERNAME@$TARGET_HOSTNAME" mkdir -p "$DEST_DIR"
    SCP_RETVAL=$?; if [[ $SCP_RETVAL = 0 ]]; then printf "OK.\n"; else printf "Directory creation failed with error $SCP_RETVAL.\n"; return 1; fi

    scp "$SOURCE_DIR/$FILE_NAME" "$TARGET_USERNAME@$TARGET_HOSTNAME:$DEST_DIR/$FILE_NAME"
    SCP_RETVAL=$?; if [[ $SCP_RETVAL = 0 ]]; then printf "OK.\n"; else printf "Copy failed with error $SCP_RETVAL.\n"; return 1; fi

    return 0
}

# deploy the files to the router

ERR=0
deploy_file "$TARGET_ROUTER_USERNAME" "$TARGET_ROUTER_IP" "$AU_CFG_FILE_NAME"    "$AU_CFG_FILE_SOURCE_DIR"    "$AU_CFG_FILE_DEST_DIR";    RETVAL=$?; if [[ $RETVAL != 0 ]]; then ERR=1; fi
deploy_file "$TARGET_ROUTER_USERNAME" "$TARGET_ROUTER_IP" "$AU_SCRIPT_FILE_NAME" "$AU_SCRIPT_FILE_SOURCE_DIR" "$AU_SCRIPT_FILE_DEST_DIR"; RETVAL=$?; if [[ $RETVAL != 0 ]]; then ERR=1; fi

# if the files deployment failed
if [[ $ERR != 0 ]]; then printf "Exitting with error $ERR."; exit $ERR; fi


exit 0
