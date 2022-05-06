#!/bin/bash
##
##          This will setup CheckMK Agent
##      Date: Oct 14, 2021     Author: Sethu Madhavan
##      Version: 5.2.3         License: GPL v3

echo -e "\n\n\nCheckMK Automation Tool - 5.2.3\nContact: SRE Team\n"
echo -e "\n\t\t`date`\n\t\tInstalling and configuring CheckMK Agent in /opt/CheckMK...\n\n"
echo -e "\nSystem Requirement Packages: xinetd,jq,checkmk"

# User Check - root
if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root!!!"
   exit 1
fi

SDIR="/opt/CheckMK"
mkdir $SDIR

if [[ ! -f "$SDIR/cmk_agent.bin" ]]; then
    mv $0 $SDIR/cmk_agent.bin
fi

if [[ ! -f "$SDIR/cmk_agent.cf" ]]
then
        {
                echo -e "\n\nMissing config file - cmk_agent.cf"
                echo -e "Creating a Default Default Cofiguration, see cmk_agent.cf\n\n"
                cat <<- EOF > $SDIR/cmk_agent.cf
#
#   Configuration File for CheckMK Agent
#
CMK="cmk.local"
SITE="controller"
TYPE=""
CMID="automation"
KEY="2342-key"
CMK_AGENT="check-mk-agent_2.0.0p18-1_all.deb"
EOF
        }
fi

validate_site () {
    ACCOUNT=`curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.accountId'`
    if [ $ACCOUNT == 1234 ]; then
            {
                MSITE="prod"
            }
    elif [ $ACCOUNT == 1111 ]; then
            {
                MSITE="uat"
            }
    fi
}

# Get Info
IP=`curl -s http://169.254.169.254/latest/meta-data/local-ipv4`

get_config () {
    typeset -A config
    config=(
        [CMK]=""
        [SITE]=""
        [TYPE]=""
        [CMID]=""
        [KEY]=""
        [CMK_AGENT]=""
    )
    while read line
    do
        if echo $line | grep -F = &>/dev/null
        then
            varname=$(echo "$line" | cut -d '=' -f 1)
            config[$varname]=$(echo "$line" | cut -d '=' -f 2- | cut -d'"' -f2)
        fi
    done < $SDIR/cmk_agent.cf

    CMK=${config[CMK]}
    SITE=${config[SITE]}
    TYPE=${config[TYPE]}
    CMID=${config[CMID]}
    KEY=${config[KEY]}
    CMK_AGENT=${config[CMK_AGENT]}
}

call_api() {
    API_URL="http://$CMK/$SITE/check_mk/api/1.0/$API"
    out=$(curl -s \
            --request POST \
            --write-out "\nxxx-status_code=%{http_code}\n" \
            --header "Authorization: Bearer $CMID $KEY" \
            --header "Accept: application/json" \
            --header "Content-Type: application/json" \
            --data '{'$DATA'}' \
                "$API_URL")
    code=$(echo "${out}" | awk -F"=" '/^xxx-status_code/ {print $2}')
    echo "${out}"
    if [[ $code -lt 400 ]]; then
        echo -e "\nSUCCESS - $CALL\n"
    else
        echo -e "\nRequest ERROR\n"
    fi
}


# Update Monitor
add_mon() {
    echo -e "\nAdding HOST $HOST on $MSITE\n"
    API="domain-types/host_config/collections/all"
    DATA='"attributes":{"ipaddress":"'$IP'"},"folder":"'\~$FOLDER'","host_name":"'$HOST'"'
    CALL="Host Added"
    call_api
}

discovery() {
    echo -e "\nStarting Service Discovery for $HOST\n"
    API="objects/host/$HOST/actions/discover_services/invoke"
    DATA='"mode":"refresh"'
    CALL="Service Discovery"
    call_api
}

apply_change() {
    echo -e "\nApplying the Changes...\n"
    API="domain-types/activation_run/actions/activate-changes/invoke"
    DATA='"force_foreign_changes":false,"redirect":false,"sites":["'$MSITE'"]'
    CALL="Applied Changes"
    call_api
}

# Get Configuration
get_config

# Validate Site
validate_site

if [ -z $TYPE ]; then
        {
         FOLDER="$MSITE"
        }
else
        {
        FOLDER="$MSITE"_"$TYPE"
        }
fi

# Sleep for for CFT to complete
SLP=${1:-1200}
echo "Sleeping....$SLP"
sleep $SLP

# Add Monitor
HOST=`hostname -s`
add_mon

# Starting Service Discovery
discovery

# Save the Change
sleep 20 # wait for service discovery
apply_change


# END
