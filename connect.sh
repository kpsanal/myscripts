######################################################################
#
#   Updated: June 11, 2018    Version: 3.2
#
#	Script will help to reduce manual entry of IP or KeyName
#	of AWS instances running on all accounts
#
######################################################################
#/bin/bash!
KeysDir="/opt/opstools/KEYS"
HostsDir="/opt/opstools/AWSInstances"
pass="XYZ-PASS";
ue=$1
if [ -z $ue ]; then
	{
	clear;
        echo -e "\n\t\t\t***** AWS Connect Tool *****\n";
	echo -e "\n\n\tUasge:\n\t\t connect <HOST NAME> or <IP Address> or <Instance Id>\n\n";
	exit 0;
	}
fi
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
                key="$KeysDir/$ac-ec2-keys/$kf.pem";
		sudo chown $USER:netops $key
		sudo chmod 600 $key
	}
fi
clear
echo -e "\n\t\t\t***** AWS Connect Tool *****\n";
	echo -e "\n IP: $ip \t\t\t\tAuthor: $au\n Hostname: $hn \t\t\tEnvironment: $AC $env\n KeyName: $kf \t\t\t\tGroup: $gp\n";
if  [ -e $key ]; then
	{
#echo "KEY -- $key";
	ssh -i $key -oBatchMode=yes -oStrictHostKeyChecking=no -oConnectTimeout=10 ubuntu@$ip || ssh -i $key -oBatchMode=yes -oStrictHostKeyChecking=no -oConnectTimeout=10 ec2-user@$ip || ssh -i $key -oBatchMode=yes -oStrictHostKeyChecking=no -oConnectTimeout=10 centos@$ip || sshpass -p $pass ssh -oStrictHostKeyChecking=no -oConnectTimeout=10 sysadmin@$ip || echo -e "\nI'm sorry...... :( $ue is NOT Accessible\n" < /dev/null;
	echo -e "\n\tGood Bye!!\n"
	exit 0;
	}
else
	{
        echo -e "\nThe Key $kf.pem not available. Please drop an email to Infra Team";
	sshpass -p $pass ssh -oStrictHostKeyChecking=no -oConnectTimeout=10 sysadmin@$ip || echo -e "\nI'm sorry...... :( $ue is NOT Accessible\n\n" < /dev/null;
	echo -e "\n\tGood Bye!!\n";
	exit 0;
        }
fi
#END
