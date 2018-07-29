######################################################################
#
#               AWS Instance List
#       Updated: July 29, 2018    Version: 2.1
#
######################################################################
#!/bin/bash
# Defining environment specifically for Cron
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export SHELL=/bin/bash

for u in ap-user appe-user;
        do
        for r in eu-west-1 us-east-1;
                do
                ac=`echo $u | cut -d'-' -f1`
                aws ec2 describe-instances --region $r --profile $u --output text --query 'Reservations[*].Instances[*].[Placement.AvailabilityZone, InstanceId, InstanceType, KeyName, State.Name, LaunchTime, Placement.Tenancy, PrivateIpAddress, PrivateDnsName, PublicDnsName, Platform, [Tags[?Key==`Name`].Value] [0][0], [Tags[?Key==`Environment`].Value] [0][0], [Tags[?Key==`Author`].Value] [0][0], [Tags[?Key==`Service`].Value] [0][0], [Tags[?Key==`aws:autoscaling:groupName`].Value] [0][0] ]' > /opt/opstools/AWSInstances/instances-$ac-$r.csv
                sed -i 's/\t/;/g' /opt/opstools/AWSInstances/instances-$ac-$r.csv
                echo -e "\nCompleted $ac $r\n";
                done;
        done;
#END
