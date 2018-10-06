#!/bin/ash

printf "OpenWrt-Autoupgrader\n"

# configuration file path
CFG_FILE=/usr/local/etc/openwrt-autoupgrader

# load the configuration
printf "Loading the configuration from file $CFG_FILE...\n"

# configure the separator
IFS="="

# initialize the default values
ROUTER_HW_BRAND=""
ROUTER_HW_MODEL=""
ROUTER_HW_VERSION=""

# parse the config file
while read -r name value
do
    if [[ "$name" = "router_hw_brand"   ]]; then ROUTER_HW_BRAND="${value//\"/}";       fi
    if [[ "$name" = "router_hw_model"   ]]; then ROUTER_HW_MODEL="${value//\"/}";       fi
    if [[ "$name" = "router_hw_version" ]]; then ROUTER_HW_VERSION="${value//\"/}";     fi
done < $CFG_FILE

# dump the loaded configuration
printf "Router hardware configuration:\n"
printf "\trouter hardware brand:   $ROUTER_HW_BRAND\n"
printf "\trouter hardware model:   $ROUTER_HW_MODEL\n"
printf "\trouter hardware version: $ROUTER_HW_VERSION\n"

# Checking the upgrade availability

# construct the Table of HW URL
TABLE_OF_HW_URL="https://openwrt.org/toh/start"
URL_NEXT_SEPARATOR="?"

if [[ "$ROUTER_HW_BRAND" != "" ]]; then TABLE_OF_HW_URL="$TABLE_OF_HW_URL${URL_NEXT_SEPARATOR}dataflt%%5BBrand*~%%5D=$ROUTER_HW_BRAND"; URL_NEXT_SEPARATOR="&"; fi
if [[ "$ROUTER_HW_MODEL" != "" ]]; then TABLE_OF_HW_URL="$TABLE_OF_HW_URL${URL_NEXT_SEPARATOR}dataflt%%5BModel*~%%5D=$ROUTER_HW_MODEL"; URL_NEXT_SEPARATOR="&"; fi
if [[ "$ROUTER_HW_VERSION" != "" ]]; then TABLE_OF_HW_URL="$TABLE_OF_HW_URL${URL_NEXT_SEPARATOR}dataflt%%5BVersions*~%%5D=$ROUTER_HW_VERSION"; URL_NEXT_SEPARATOR="&"; fi

printf "URL: $TABLE_OF_HW_URL\n"

<table class="inline dataplugin_table

</table>