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

if [[ "$ROUTER_HW_BRAND" != "" ]]; then TABLE_OF_HW_URL="$TABLE_OF_HW_URL${URL_NEXT_SEPARATOR}dataflt[Brand*~]=$ROUTER_HW_BRAND"; URL_NEXT_SEPARATOR="&"; fi
if [[ "$ROUTER_HW_MODEL" != "" ]]; then TABLE_OF_HW_URL="$TABLE_OF_HW_URL${URL_NEXT_SEPARATOR}dataflt[Model*~]=$ROUTER_HW_MODEL"; URL_NEXT_SEPARATOR="&"; fi
if [[ "$ROUTER_HW_VERSION" != "" ]]; then TABLE_OF_HW_URL="$TABLE_OF_HW_URL${URL_NEXT_SEPARATOR}dataflt[Versions*~]=$ROUTER_HW_VERSION"; URL_NEXT_SEPARATOR="&"; fi

TABLE_OF_HW_FILE="/tmp/openwrt_autoupgrader_table_of_HW.html"

printf "Downloading the OpenWrt table of HW from $TABLE_OF_HW_URL into $TABLE_OF_HW_FILE..."

wget -O "$TABLE_OF_HW_FILE" "$TABLE_OF_HW_URL"
WGET_RETVAL=$?; if [[ $WGET_RETVAL = 0 ]]; then printf "OK.\n"; else printf "Wget failed with error $WGET_RETVAL.\n"; exit 1; fi

# Check the number of lines returned in the table with the returned versions of firmware matching the criteria.
# Each row is prefixed with the '<tr><td class="leftalign rownumbers">', followed with the row index. There should be just the number 1.

# Count the line containing the text '<tr><td class="leftalign rownumbers">1</td>'
ROW_N_1_COUNT=`grep '<tr><td class="leftalign rownumbers">1</td>' "$TABLE_OF_HW_FILE" | wc -l`

# Count the line containing the text '<tr><td class="leftalign rownumbers">2</td>'
ROW_N_2_COUNT=`grep '<tr><td class="leftalign rownumbers">2</td>' "$TABLE_OF_HW_FILE" | wc -l`

# If the row #1 was not found, fail with error
if [[ "$ROW_N_1_COUNT" != "1" ]]; then printf "Error: No releases found in the supported HW list for the specified HW configuration. Please check your HW parameters."; exit 1; fi

# If the row #2 was found, fail with error
if [[ "$ROW_N_2_COUNT" != "0" ]]; then printf "Error: More than one releases found in the supported HW list for the specified HW configuration. Please check your HW parameters."; exit 1; fi

printf "One release found in the supported HW list for the specified HW.\n"

# we will replace the text right before and after the release version on the HTML code by the horizontal pipes | and then use awk 
# to print what is in between
TO_BE_REPLACED_1='<td class=\"centeralign supported_current_rel\"><a href=\"\/releases\/'
TO_BE_REPLACED_2='\" class=\"wikilink1\"'

RELEASE_URL=`grep '<tr><td class="leftalign rownumbers">1</td>' "$TABLE_OF_HW_FILE" | sed "s/$TO_BE_REPLACED_1/|/g" | sed "s/$TO_BE_REPLACED_2/|/g" | awk -F  "|" '{print $2}'`

printf "Detected release version is \"$RELEASE_URL\".\n"

printf "To be continued.\n"
