#
#	Setting up CloudWatch Metrix
#
#	Upated Jun 17, 2018
#
#!/bin/sh
apt=`command -v apt-get`
yum=`command -v yum`
if [ -n "$apt" ]; then
	{
	sudo apt-get update; apt-get install unzip -y;
	sudo apt-get install libwww-perl libdatetime-perl -y;
	}
elif [ -n "$yum" ]; then
	{
	sudo yum makecache;
	sudo yum install perl-Switch perl-DateTime perl-Sys-Syslog perl-LWP-Protocol-https -y;
	}
else
	echo "Err: no path to apt-get or yum" >&2;
	exit 1;
fi
# Setiing up the cloud watch
	sudo wget https://aws-cloudwatch.s3.amazonaws.com/downloads/CloudWatchMonitoringScripts-1.2.2.zip -O /tmp/cloudwatch.zip
	sudo unzip -o /tmp/cloudwatch.zip -d /opt/opstools/
	sudo rm -f /tmp/cloudwatch.zip
	/opt/opstools/aws-scripts-mon/./mon-put-instance-data.pl --mem-used-incl-cache-buff --mem-util --mem-used --mem-avail
# Setting up the cron job
	sudo crontab -l > /tmp/mycron.tmp;
	sudo sed -i '/mon-put-instance-data/d' /tmp/mycron.tmp;
	echo "*/5 * * * * /opt/opstools/aws-scripts-mon/mon-put-instance-data.pl --mem-util --disk-space-util --disk-path=/ --from-cro" >> /tmp/mycron.tmp;
	sudo sort -u /tmp/mycron.tmp > /tmp/mycron.ok;
	sudo crontab /tmp/mycron.ok;
	sudo rm -f /tmp/mycron*
	sudo service cron reload
# verify the Cloudwatch installation status
	/opt/opstools/aws-scripts-mon/./mon-get-instance-stats.pl --recent-hours=12 
# END
