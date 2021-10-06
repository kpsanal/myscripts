#!/bin/bash
##
##      This will setup CheckMK Agent
##      Version: 4.4.2
##
echo -e "\n\n\nCheckMK Automation Tool - 4.4.2\n"
echo -e "\n\t\t`date`\n\t\tInstalling and configuring CheckMK Agent...\n\n"
SDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

if [[ ! -f "$SDIR/cmk_agent.cf" ]]
then
        {
                echo -e "\n\nMissing config file - cmk_agent.cf"
                echo -e "Creating a Mscripts Default Default Cofiguration, see cmk_agent.cf\n\n"
                cat <<- EOF > cmk_agent.cf
#
#   Configuration File for CheckMK Agent
#
CMK="cmk.site.local"
SITE="site"
CMID="automation"
KEY="xxxxxxxx"
CMK_AGENT="check-mk-agent.deb"
EOF
        }
fi

# Reregister at every system reboot
set_cron () {
echo -e "\nUpdating Cronjob"
# @reboot /opt/CheckMK/cmk_agent.bin > /var/log/cmk_agent_install.log
}

validate_site () {
    ACCOUNT=`curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.accountId'`
    if [ $ACCOUNT == 2222 ]; then
            {
                    FOLDER="prod"
            }
    elif [ $ACCOUNT == 11111 ]; then
            {
                    FOLDER="uat"
            }
    fi
}

# Get Info
IP=`curl -s http://169.254.169.254/latest/meta-data/local-ipv4`

# Installing JQ
if ! dpkg -s jq 2> /dev/null; then
    sudo apt-get install jq -y
fi

get_config () {
    typeset -A config
    config=(
        [CMK]=""
        [SITE]=""
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

# Install Agent
install_agent () {
    if ! dpkg -s check-mk-agent 2> /dev/null; then
        {
        apt-get install xinetd -y
        echo -e "\nInstalling CheckMK Agent...\n"
        wget -q -t 1 --timeout=10 http://$CMK/$SITE/check_mk/agents/$CMK_AGENT -O /tmp/cmk.deb
        sudo dpkg -i /tmp/cmk.deb
        service xinetd restart
        }
    else
        {
        echo -e "\nCheckMK Agent is already Installed\n"
        }
    fi
}

# Update Monitor
add_mon() {
    echo -e "\nAdding HOST $HOSTNAME\n"
    API="domain-types/host_config/collections/all"
    DATA='"attributes":{"ipaddress":"'$IP'"},"folder":"'\~$FOLDER'","host_name":"'$HOSTNAME'"'
    CALL="Host Added"
    call_api
}

# 10mins DT for the host so service can come up normally.
downtime() {

    echo -e "\nPutting Host DT For - $HOSTNAME\n"
    API="domain-types​/downtime​/collections​/host"

    DATA=''

    
    CALL="Host Downtime"
    call_api
}

discovery() {
    echo -e "\nStarting Service Discovery for $HOSTNAME\n"
    API="objects/host/$HOSTNAME/actions/discover_services/invoke"
    DATA='"mode":"refresh"'
    CALL="Service Discovery"
    call_api
}

apply_change() {
    echo -e "\nApplying the Changes...\n"
    API="domain-types/activation_run/actions/activate-changes/invoke"
    DATA='"force_foreign_changes":false,"redirect":false,"sites":["'$FOLDER'"]'
    CALL="Applied Changes"
    call_api
}

# Get Configuration
get_config

# Validate Site
validate_site

# Install CMK Agent
install_agent

# Add Monitor
add_mon

# Starting Service Discovery
discovery

# Save the Change
sleep 20 # wait for service discovery
apply_change

# END
