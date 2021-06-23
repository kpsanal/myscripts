#!/bin/bash
##
##      This will setup CheckMK Agent on AWS
##      Date: June 23, 2021
##

CMK="YourCMKServer"
SITE="SITE1"
USERNAME="automation"
PASSWORD="Key"

call_api() {
    API_URL="http://$CMK/$SITE/check_mk/api/1.0/$API"
    out=$(curl -s \
            --request POST \
            --write-out "\nxxx-status_code=%{http_code}\n" \
            --header "Authorization: Bearer $USERNAME $PASSWORD" \
            --header "Accept: application/json" \
            --header "Content-Type: application/json" \
            --data '{'$DATA'}' \
                "$API_URL")

    code=$(echo "${out}" | awk -F"=" '/^xxx-status_code/ {print $2}')

    if [[ $code -lt 400 ]]; then
        echo -e "\nSUCCESS - $CALL\n"
    else
        echo -e "\nRequest ERROR\n"
    fi
}

# Get Info
IP=`curl -s http://169.254.169.254/latest/meta-data/local-ipv4`

# Install Agent
dpkg -s 'check-mk-agent' &> /dev/null
if [ $? -ne 0 ]; then
    {
    echo -e "\nInstalling CheckMK Agent...\n"
    wget -q -t 1 --timeout=10 http://$CMK/$SITE/check_mk/agents/check-mk-agent_2.0.0p5-1_all.deb -O /tmp/cmk.deb
    sudo dpkg -i /tmp/cmk.deb
    }
else
    {
    echo -e "\nCheckMK Agent is already Installed\n"
    }
fi

# Update Monitor
add_mon() {
    echo "Adding HOST $HOSTNAME"
    API="domain-types/host_config/collections/all"
    DATA='"attributes":{"ipaddress":"'$IP'"},"folder":"\/","host_name":"'$HOSTNAME'"'
    CALL="Host Added"
    call_api
}

discovery() {
    echo "Starting Service Discovery for $HOSTNAME"
    API="objects/host/$HOSTNAME/actions/discover_services/invoke"
    DATA='"mode":"refresh"'
    CALL="Service Discovery"
    call_api
}

apply_change() {
    API="domain-types/activation_run/actions/activate-changes/invoke"
    DATA='"force_foreign_changes":false,"redirect":false,"sites":["'$SITE'"]'
    CALL="Applied Changes"
    call_api
}

# Add Monitor
add_mon

# Starting Service Discovery
discovery

# Save the Change
sleep 20 # wait for service discovery
apply_change

# END
