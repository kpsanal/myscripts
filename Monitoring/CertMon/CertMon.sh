#!/bin/bash
##
##       Cert Mon - SSL Validator
##       Version 3.6.4   Date: Aug 4, 2021
##
# set -ex
VERSION="CertMon Version: 3.5.3"
echo $VERSION
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
if [[ ! -f "$SCRIPT_DIR/cert-mon.conf" ]]
then
        {
                echo -e "\n\nMissing config file - cert-man.conf"
                echo -e "See cert-mon.conf.sample\n\n"
                cat <<- EOF > cert-man.conf.sample
#       Cert Man - Sample Configuration File
WEBHOOK="https://hooks.slack.com/" # Slack Webhook test
SLACK_CHANNEL="#test123" #Channel Name
SLACK_BOTNAME="Cert Man" # Bot Name
FQDNS="/ubuntu/abcd" # File with Wesites Eg: www.example.com. And NOT http://www.example.com
EXPIRY="60" # Number of Days before Expiry to notify
EOF
                exit 1;
        }
fi
typeset -A config
config=(
    [WEBHOOK]=""
    [SLACK_CHANNEL]=""
    [SLACK_BOTNAME]=""
    [FQDNS]=""
    [EXPIRY]=""
)
while read line
do
    if echo $line | grep -F = &>/dev/null
    then
        varname=$(echo "$line" | cut -d '=' -f 1)
        config[$varname]=$(echo "$line" | cut -d '=' -f 2- | cut -d'"' -f2)
    fi
done < $SCRIPT_DIR/cert-man.conf


WEBHOOK=${config[WEBHOOK]}
SLACK_CHANNEL=${config[SLACK_CHANNEL]}
SLACK_BOTNAME=${config[SLACK_BOTNAME]}
FQDNS=${config[FQDNS]}
EXPIRY=${config[EXPIRY]}


if [[ -z ${config[WEBHOOK]} || -z ${config[SLACK_CHANNEL]} || -z ${config[SLACK_BOTNAME]} || -z ${config[FQDNS]} || -z ${config[EXPIRY]} ]]
then
        {
                echo -e "\n\n\tPlease verify cert-man.conf\n\n"
                exit 1;
        }
fi

slack() {
        curl -X POST --data-urlencode "$SLACK_PAYLOAD" $WEBHOOK
        }
begin() {
        SLACK_PAYLOAD="payload={\"text\":\"*Certs expiring in $EXPIRY days will be displayed* - $VERSION\"}"
        slack

        }
finish() {
        SLACK_PAYLOAD="payload={\"text\":\"*Completed*\"}"
        slack
        }
notify() {
        DOMAIN="$1"
        EXPIRY_DAYS="$2"
        EXPIRY_DATE="$3"
        ISSUER="$4"
        COLOR="$5"
        IP_ADDR="$6"
        CERT_NAME="$7"
        if [ "$EXPIRY_DAYS" -gt "$EXPIRY" ]; then
                {
                        echo "Cert is valid"
                }
        else
                {
                        sleep 1; #avoid rate limiting at slack
                        SLACK_PAYLOAD="payload={\"channel\":\"${SLACK_CHANNEL}\",\"username\":\"${SLACK_BOTNAME}\",\"attachments\":[{\"color\":\"${COLOR}\",\"fields\":[{\"title\":\"FQDN:\",\"value\":\"${DOMAIN}\",\"short\":true},{\"title\":\"Expiry day(s):\",\"value\":\"${EXPIRY_DAYS}\",\"short\":true},{\"title\":\"Server IP:\",\"value\":\"${IP_ADDR}\",\"short\":true},{\"title\":\"Expiry date:\",\"value\":\"$EXPIRY_DATE\",\"short\":true},{\"title\":\"Issued by:\",\"value\":\"$ISSUER\",\"short\":true}, {\"title\":\"Cert Name:\",\"value\":\"$CERT_NAME\",\"short\":true}]}]}"
                        slack
                }
        fi
        }
check_certs() {
        if [ -z "$1" ]; then
                echo -e "Please enter FQDN\n\n"
                exit 1
        fi
        name="$1"
        shift
        now_epoch=$(date +%s)
        ip_server=$(dig +short $name)
        dig +noall +answer +short $name | tail -1 | while read -r ip; do
                data=$(echo | timeout 5 openssl s_client -showcerts -servername $name -connect $ip:443 </dev/null 2>/dev/null | openssl x509 -noout -enddate -issuer -ext subjectAltName)
                expiry_date=$(echo $data | grep -Eo "notAfter=(.*)GMT" | cut -d "=" -f 2)
                issuer=$(echo $data | grep -Eo "O = (.*,)" | cut -d'=' -f2 | cut -d',' -f1)
                expiry_epoch=$(date -d "$expiry_date" +%s)
                expiry_days="$((($expiry_epoch - $now_epoch) / (3600 * 24)))"
                cert_name=$(echo $data | grep "DNS" | grep -Po "(?<=DNS\:).*?(?=\,)" | head -1)
                if [ $expiry_days -lt 60 ]; then # No notification for certs exp mre than 2 months
                        color="#ff0000"
                        notify "$name" "$expiry_days" "$expiry_date" "$issuer" "$color" "$ip" "$cert_name"
                else
                        color="#2eb886"
                fi
        done
        }
# Read input from the file.
if [[ ! -f "$FQDNS" ]]
then
        {
        echo -e "\n\nPlease update the FQDNS - filename in the cert-mon.conf\nExiting..\n"
        exit 1;
        }
fi

begin
while read fqdn; do
        check_certs $fqdn
done <$FQDNS
finish
# END
