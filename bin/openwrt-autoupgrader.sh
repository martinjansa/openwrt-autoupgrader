#!/bin/ash

printf "OpenWrt-Autoupgrader\n"

# Get the currently installed OpenWrt version

CURRENT_RELEASE_FILE="/etc/openwrt_release"

# load the values from the /etc/openwrt_release
source "$CURRENT_RELEASE_FILE"

INSTALLED_OPENWRT_VERSION=$DISTRIB_RELEASE
INSTALLED_OPENWRT_TARGET=$DISTRIB_TARGET

printf "Installed OpenWrt version is $INSTALLED_OPENWRT_VERSION, target $INSTALLED_OPENWRT_TARGET.\n"


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
ROUTER_HWDATA_URL=""

# parse the config file
while read -r name value
do
    if [[ "$name" = "router_hw_brand"   ]]; then ROUTER_HW_BRAND="${value//\"/}";       fi
    if [[ "$name" = "router_hw_model"   ]]; then ROUTER_HW_MODEL="${value//\"/}";       fi
    if [[ "$name" = "router_hw_version" ]]; then ROUTER_HW_VERSION="${value//\"/}";     fi
    if [[ "$name" = "router_hwdata_url" ]]; then ROUTER_HWDATA_URL="${value//\"/}";     fi
done < $CFG_FILE

# dump the loaded configuration
printf "Router hardware configuration:\n"
printf "\trouter hardware brand:    $ROUTER_HW_BRAND\n"
printf "\trouter hardware model:    $ROUTER_HW_MODEL\n"
printf "\trouter hardware version:  $ROUTER_HW_VERSION\n"
printf "\trouter hardware data URL: $ROUTER_HWDATA_URL\n"


# Getting the latest upgrade version

# construct the Table of HW URL
TABLE_OF_HW_URL="https://openwrt.org/toh/start"
URL_NEXT_SEPARATOR="?"

if [[ "$ROUTER_HW_BRAND" != "" ]]; then TABLE_OF_HW_URL="$TABLE_OF_HW_URL${URL_NEXT_SEPARATOR}dataflt[Brand*~]=$ROUTER_HW_BRAND"; URL_NEXT_SEPARATOR="&"; fi
if [[ "$ROUTER_HW_MODEL" != "" ]]; then TABLE_OF_HW_URL="$TABLE_OF_HW_URL${URL_NEXT_SEPARATOR}dataflt[Model*~]=$ROUTER_HW_MODEL"; URL_NEXT_SEPARATOR="&"; fi
if [[ "$ROUTER_HW_VERSION" != "" ]]; then TABLE_OF_HW_URL="$TABLE_OF_HW_URL${URL_NEXT_SEPARATOR}dataflt[Versions*~]=$ROUTER_HW_VERSION"; URL_NEXT_SEPARATOR="&"; fi

TABLE_OF_HW_FILE="/tmp/openwrt_autoupgrader_table_of_hw.html"

printf "Downloading the OpenWrt table of HW from '$TABLE_OF_HW_URL' into $TABLE_OF_HW_FILE... "

wget -O "$TABLE_OF_HW_FILE" "$TABLE_OF_HW_URL" > /dev/null 2>&1
WGET_RETVAL=$?; if [[ $WGET_RETVAL = 0 ]]; then printf "OK.\n"; else printf "Wget failed with error $WGET_RETVAL.\n"; exit 1; fi

# Check the number of lines returned in the table with the returned versions of firmware matching the criteria.
# Each row is prefixed with the '<tr><td class="leftalign rownumbers">', followed with the row index. There should be just the number 1.

# Count the line containing the text '<tr><td class="leftalign rownumbers">1</td>'. If the row #1 was not found, fail with error.
ROW_N_1_COUNT=`grep '<tr><td class="leftalign rownumbers">1</td>' "$TABLE_OF_HW_FILE" | wc -l`
if [[ "$ROW_N_1_COUNT" != "1" ]]; then printf "Error: No releases found in the supported HW list for the specified HW configuration. Please check your HW parameters.\n"; exit 1; fi

# Count the line containing the text '<tr><td class="leftalign rownumbers">2</td>'. If the row #2 was found, fail with error.
ROW_N_2_COUNT=`grep '<tr><td class="leftalign rownumbers">2</td>' "$TABLE_OF_HW_FILE" | wc -l`
if [[ "$ROW_N_2_COUNT" != "0" ]]; then printf "Error: More than one releases found in the supported HW list for the specified HW configuration. Please check your HW parameters.\n"; exit 1; fi

# Check that the returned line contains the link to the hardware date page specified in the config file
ROW_HWDATA_COUNT=`grep '<tr><td class="leftalign rownumbers">1</td>' "$TABLE_OF_HW_FILE" | grep "$ROUTER_HWDATA_URL" | wc -l`
if [[ "$ROW_HWDATA_COUNT" != "1" ]]; then printf "Error: The hardware data URL does not match the one found in the supported HW list for the specified HW configuration. Please check your HW parameters."; exit 1; fi

printf "One release found in the supported HW list for the specified HW.\n"

# we will replace the text right before and after the release version on the HTML code by the horizontal pipes | and then use awk 
# to print what is in between
TO_BE_REPLACED_1='<td class=\"centeralign supported_current_rel\"><a href=\"\/releases\/'
TO_BE_REPLACED_2='\" class=\"wikilink1\"'

DETECTED_LATEST_OPENWRT_VERSION=`grep '<tr><td class="leftalign rownumbers">1</td>' "$TABLE_OF_HW_FILE" | sed "s/$TO_BE_REPLACED_1/|/g" | sed "s/$TO_BE_REPLACED_2/|/g" | awk -F  "|" '{print $2}'`

printf "Detected latest available release version is $DETECTED_LATEST_OPENWRT_VERSION.\n"

rm "$TABLE_OF_HW_FILE"


# Comparing of the current and available release version

# if the installed OpenWrt version is different than the available version
if [[ "$INSTALLED_OPENWRT_VERSION" = "$DETECTED_LATEST_OPENWRT_VERSION" ]]; then printf "The latest version is already installed.\n"; exit 0; fi


# Getting the upgrade binary URL

# We will parse the hardware data page and search for the href with the .bin file

HW_DATA_FILE="/tmp/openwrt_autoupgrader_hw_data_file.html"

printf "Downloading the OpenWrt hardware data page 'https://openwrt.org$ROUTER_HWDATA_URL' into $HW_DATA_FILE... "

wget -O "$HW_DATA_FILE" "https://openwrt.org$ROUTER_HWDATA_URL" > /dev/null 2>&1
WGET_RETVAL=$?; if [[ $WGET_RETVAL = 0 ]]; then printf "OK.\n"; else printf "Wget failed with error $WGET_RETVAL.\n"; exit 1; fi

# Check that the page contains a line with the upgrade URL
UPGRADE_URL_PREFIX="<dd class=\"firmware_openwrt_upgrade_url\"><a href='"

# Count the lines containing the upgrade URL prefix. If not just one row was not found, fail with error.
UPGRADE_URL_ROWS_COUNT=`grep "$UPGRADE_URL_PREFIX" "$HW_DATA_FILE" | wc -l`
if [[ "$UPGRADE_URL_ROWS_COUNT" != "1" ]]; then printf "Error: The numner of row with the upgrade URL does not match 1. ($UPGRADE_URL_ROWS_COUNT). Please check your HW parameters.\n"; exit 1; fi

# get the URL of the upgrade bin (grep the line, cut everything before the prefix (inclusive), cut everything behind the apostroph)
UPGRADE_BIN_URL=`grep "$UPGRADE_URL_PREFIX" "$HW_DATA_FILE" | sed "s/$UPGRADE_URL_PREFIX/|/g" | awk -F  "|" '{print $2}' | awk -F  "'" '{print $1}'`

printf "Detected upgrade bin URL is \"$UPGRADE_BIN_URL\".\n"

rm "$HW_DATA_FILE"


# Cross-checks of the upgrade bin URL:
#  - should contain the latest version detected before.
#  - should contain the current distribution target.
#  - should contain the suffix "-sysupgrade.bin".

if [[ "`echo $UPGRADE_BIN_URL | grep $DETECTED_LATEST_OPENWRT_VERSION | wc -l`" != "1" ]]; then printf "Error: Detected upgrade bin URL does not contain the expected release version.\n"; exit 1; fi
if [[ "`echo $UPGRADE_BIN_URL | grep $INSTALLED_OPENWRT_TARGET        | wc -l`" != "1" ]]; then printf "Error: Detected upgrade bin URL does not contain the expected release target.\n"; exit 1; fi
if [[ "`echo $UPGRADE_BIN_URL | grep 'sysupgrade.bin'                 | wc -l`" != "1" ]]; then printf "Error: Detected upgrade bin URL does not contain the expected suffix \"sysupgrade.bin\".\n"; exit 1; fi


# Download the bin file

UPGRADE_BIN_FILE=/tmp/openwrt`echo $UPGRADE_BIN_URL | sed "s/\/openwrt/|/g" | awk -F  "|" '{print $2}'`

printf "Downloading the OpenWrt upgrade bin file into $UPGRADE_BIN_FILE... "

wget -O "$UPGRADE_BIN_FILE" "$UPGRADE_BIN_URL" > /dev/null 2>&1
WGET_RETVAL=$?; if [[ $WGET_RETVAL = 0 ]]; then printf "OK.\n"; else printf "Wget failed with error $WGET_RETVAL.\n"; exit 1; fi

printf "Now you should verify the sha265 of the file $UPGRADE_BIN_FILE and then run sysupgrade -v $UPGRADE_BIN_FILE.\n"
printf "To be continued.\n"
