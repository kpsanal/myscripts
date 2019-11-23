######################################################################
#
#               AWS Instance List
#       Updated: Nov 23, 2019    Version: 1.0
#
######################################################################
#!/bin/bash
# Defining environment specifically for Cron
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export SHELL=/bin/bash

        for r in ap-south-1 ap-southeast-2 eu-west-1 us-east-1 us-west-1;
                do
                aws ec2 describe-instances --region $r --output text --query 'Reservations[*].Instances[*].[Placement.AvailabilityZone, InstanceId, InstanceType, KeyName, State.Name, LaunchTime, Placement.Tenancy, PrivateIpAddress, PrivateDnsName, PublicDnsName, [Tags[?Key==`Name`].Value] [0][0], [Tags[?Key==`Environment`].Value] [0][0], [Tags[?Key==`Author`].Value] [0][0], [Tags[?Key==`Service`].Value] [0][0] ]' > AWSInstances/instances-$r.csv
                sed -i 's/\t/;/g' AWSInstances/instances-$r.csv
                echo -e "\nCompleted $r\n";
                done;
#END
