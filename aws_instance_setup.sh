
#############################################################################
#
#	This script is to setup all basic requirements of instances 
#	running at T&F AWS Cloud
#
#############################################################################

# Set Banner
sudo wget http://tools.ap.corplan.net/banner.txt -O /etc/banner.txt
sudo sed -i '/Banner/c\Banner /etc/banner.txt' /etc/ssh/sshd_config
sudo service ssh restart || sudo service sshd restart;

# Setup NTP

