#!/bin/bash
# set -ex
slack() {
        WEBHOOK="Your Slack"
        SLACK_CHANNEL="#Your-Slack-Channel-Name"
        SLACK_BOTNAME="SSL Tester"
        curl -X POST --data-urlencode "$SLACK_PAYLOAD" $WEBHOOK
}
begin() {
        SLACK_PAYLOAD="payload={\"text\":\"*Certs expiring in 60 days will be displayed*\"}"
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
        if [ "$EXPIRY_DAYS" -gt "60" ]; then
                {
                echo "Cert is valid"
                }
        else
                {
                SLACK_PAYLOAD="payload={\"channel\":\"${SLACK_CHANNEL}\",\"username\":\"${SLACK_BOTNAME}\",\"attachments\":[{\"color\":\"${COLOR}\",\"fields\":[{\"title\":\"FQDN:\",\"value\":\"${DOMAIN}\",\"short\":true},{\"title\":\"Expiry day(s):\",\"value\":\"${EXPIRY_DAYS}\",\"short\":true},{\"title\":\"Server IP:\",\"value\":\"${IP_ADDR}\",\"short\":true},{\"title\":\"Expiry date:\",\"value\":\"$EXPIRY_DATE\",\"short\":true},{\"title\":\"Issued by:\",\"value\":\"$ISSUER\",\"short\":true}, {\"title\":\"Cert Name:\",\"value\":\"$CERT_NAME\",\"short\":true}]}]}"
                }
        fi
        # Send Message
        slack
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
        dig +noall +answer +short $name | while read -r ip; do
                data=$(echo | timeout 5 openssl s_client -showcerts -servername $name -connect $ip:443 </dev/null 2>/dev/null | openssl x509 -noout -enddate -issuer -ext subjectAltName)
                expiry_date=$(echo $data | grep -Eo "notAfter=(.*)GMT" | cut -d "=" -f 2)
                issuer=$(echo $data | grep -Eo "O = (.*,)" | cut -d'=' -f2 | cut -d',' -f1)
                expiry_epoch=$(date -d "$expiry_date" +%s)
                expiry_days="$((($expiry_epoch - $now_epoch) / 86400 ))"
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
list=$1
if [ -z "$list" ]; then
        echo "Please use enter the list"
fi
begin
while read fqdn; do
        check_certs $fqdn
done <$list
finish
