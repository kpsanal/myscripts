#############################################################################
#
#	This script is to setup all basic requirements of instances 
#	running at AWS Cloud
#
#############################################################################
#/bin/bash!
FileServer=YourFileServer

# Setup IP Tables

# Set Banner
sudo wget http://$FileServer/uploads/banner.txt -O /etc/banner.txt
sudo sed -i '/Banner/c\Banner /etc/banner.txt' /etc/ssh/sshd_config
sudo service ssh restart || sudo service sshd restart;
sleep 3;

# Setup NTP
curl -s http://$FileServer/scripts/ntp-setup.sh | sudo bash -

# SSM Agent
curl -s http://$FileServer/scripts/ssm-install.sh | sudo bash -

# Cloud Watch
curl -s http://$FileServer/scripts/CloudWatchInstall.sh | sudo bash -

