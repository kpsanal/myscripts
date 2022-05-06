#       Web Monitoring Tool
#       License: GNU GPL v3 - https://www.gnu.org/licenses/gpl-3.0.en.html
#       Author: Sethu Madhavan   Date: Aug 22, 2021
#       Version 2.4
#!/bin/bash

# Slack
slack() {
        WEBHOOK=""
        SLACK_CHANNEL=channel
        SLACK_BOTNAME=myBoat
        COLOR="#F50721"
        SLACK_PAYLOAD="payload={\"channel\":\"${SLACK_CHANNEL}\",\"username\":\"${SLACK_BOTNAME}\",\"attachments\":[{\"color\":\"${COLOR}\",\"fields\":[{\"title\":\"$SERVICE:\",\"value\":\"${SITE}\",\"short\":true},{\"title\":\"STATUS:\",\"value\":\"$STATUS\",\"short\":true}]}]}"
        curl -X POST --data-urlencode "$SLACK_PAYLOAD" $WEBHOOK
        }


health_check() {
        cat $ILIST | egrep -v "^#.*$" > $LIST
        sed -i '/^$/d' $LIST
        while read SITE
        do
        {
                echo "Site: $SITE"
                /opt/opstools/url-monitoring/check_website_response.sh -w 4000 -c 10000 -u $SITE
                STATUS=`cat /tmp/mkoru93`
                echo "STATUS : $STATUS"
                if [ $STATUS != "OK" ]; then
                        {
                        slack
                        }
                fi

        }
        done < $LIST
}


LIST=/opt/opstools/url-monitoring/.list

SERVICE="Microservice"
ILIST=/opt/opstools/url-monitoring/ms-urls.list
health_check


SERVICE="Jenkins"
ILIST=/opt/opstools/url-monitoring/jenkins.list
health_check

#cd /opt/opstools/url-monitoring/
rm index* get* health* login*

#END
