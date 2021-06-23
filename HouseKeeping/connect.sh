#!/bin/bash
######################################################################
#
#   Updated: June 23, 2021    Version: 4.3
#
#       Script will help to reduce manual entry of IP or KeyName
#       of AWS instances running on all accounts
#
#######################################################################
HostsDir="/opt/opstools/AWSInstances"
CONSUL="127.0.0.1"
ENV="PROD-SSH"
ue=$1
if [ -z $ue ]; then
        {
        clear;
        echo -e "\n\t\t\t***** AWS Connect Tool *****\n";
        echo -e "\n\n\tUasge:\n\t\t connect <HOST NAME> or <IP Address> or <Instance Id>\n\n";
        exit 0;
        }
fi

get_inventory(){

inventory=`grep -iRw $ue $HostsDir/*`;
sugg=`grep -iR $ue $HostsDir/* | cut -d';' --output-delimiter=$'\t' -f11,8 | sort`;
ac=`echo $inventory | awk '{print $1}' | cut -d'-' -f2`;
AC=`echo $ac | tr '[:lower:]' '[:upper:]'`;
if [ -z "$inventory" ]; then
        {
        clear;
        echo -e "\n\t\t\t***** AWS Connect Tool *****\n";
        echo -e "\n***** Error!! Invalid Host $ue";
        echo -e "\n\n\tUasge:\n\t\t connect <HOST NAME> or <IP Address> or <Instance Id>\n\n";
        echo -e "May be, you trying to connect..?? huh?? \n\n$sugg\n";
        exit 0;
        }
else
        {
                ip=`echo $inventory | cut -d';' -f8`;
                hn=`echo $inventory | cut -d';' -f11`;
                kf=`echo $inventory | cut -d';' -f4`;
                au=`echo $inventory | cut -d';' -f13`;
                env=`echo $inventory | cut -d';' -f12`;
                gp=`echo $inventory | cut -d';' -f14`;

        }
fi
}

get_key(){
        key="/tmp/$kf";
        curl -s http://$CONSUL/v1/kv/$ENV/$kf  | jq -r '.[].Value | @base64d' > $key
        sudo chown $USER:users $key
        sudo chmod 600 $key

}

get_inventory
get_key

echo -e "\n\t\t\t***** AWS Connect Tool *****\n";
        echo -e "\n IP: $ip \t\t\t\tAuthor: $au\n Hostname: $hn \t\t\t\tEnvironment: $AC $env\n KeyName: $kf \t\t\t\tGroup: $gp\n";
if  [ -e $key ]; then
        {
        ssh -i $key -q -oBatchMode=yes -oStrictHostKeyChecking=no -oConnectTimeout=60 ubuntu@$ip || echo -e "\nI'm sorry...... :( $ue is NOT Accessible\n" < /dev/null;
        echo -e "\n\tGood Bye!!\n"
#       rm $key
        exit 0;
        }
else
        {
        echo -e "\nThe Key $kf not available. Please drop an email to Infra Team";
        echo -e "\nI'm sorry...... :( $ue is NOT Accessible\n\n" < /dev/null;
        echo -e "\n\tGood Bye!!\n";
        exit 1;
        }
fi
#END
