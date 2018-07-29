#################################################################
#
#			CheckMK Agent Setup
#
#	Date: July 29, 2018		Version: 1.4
#
#################################################################
#/bin/bash!
package="xinetd"
FileServer="files.yourdomain.com"
cmkServer="checkmk.yourdomain.com"
secret="YOUR-Secret"

hostname=`hostname`
loc=`echo $hostname | cut -c 1-4`
	if [ "$loc" == "use1" ] || [ "$loc" == "USE1" ]; then
		{
		folder="tandfus"
		site="SITE1"
		}
	elif [ "$loc" == "euw1" ] || [ "$loc" == "EUW1" ]; then
		{
		folder="tandfuk"
		site="SITE2"
		}
	else	
		{
		folder="";
		site="SITE3"
		}
	fi
ip=`ifconfig | awk '{print $2}' | grep -w 10 | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b"`
curl "http://$cmkServer/TANDF/check_mk/webapi.py?action=add_host&_username=automation&_secret=$secret" -d 'request={"hostname":"'$hostname'","folder":"'$folder'","attributes":{"ipaddress":"'$ip'","site":"'$site'","tag_agent":"cmk-agent"}}'

if [ -n "$(command -v lsb_release)" ]; then
	distroname=$(lsb_release -s -d)
elif [ -f "/etc/os-release" ]; then
	distroname=$(grep PRETTY_NAME /etc/os-release | sed 's/PRETTY_NAME=//g' | tr -d '="')
elif [ -f "/etc/debian_version" ]; then
	distroname="Debian $(cat /etc/debian_version)"
elif [ -f "/etc/redhat-release" ]; then
	distroname=$(cat /etc/redhat-release)
else
	distroname="$(uname -s) $(uname -r)"
fi
OS=`echo $distroname | cut -d' ' -f1`
REL=`echo $distroname | cut -d' ' -f2 | cut -d'.' -f1`
AREL=`echo $distroname | cut -d' ' -f4 | cut -d'.' -f1`
if [ "$OS" == "Ubuntu" ]; then
	{
	dpkg -s $package &> /dev/null
	if [ $? -eq 0 ]; then
		{
    		echo "Package $package is installed!"
		}
	else
		{
		iptables -I INPUT -p tcp -s 10.0.0.0/8 --dport 6556 -j ACCEPT
		apt-get install xinetd -y
		apt-get install wget -y
		wget -q -t 1 --timeout=10 http://$FileServer/uploads/cmk.deb -O /tmp/cmk.deb; sudo dpkg -i /tmp/cmk.deb;
		wget http://$FileServer/uploads/check_mk -O /etc/xinetd.d/check_mk
		rm -f /tmp/cmk.deb
		if [ "$REL" -le "14" ]; then
			{
			#Ubuntu 14 or less
			sudo restart $package;
			}
		elif [ "$REL" -gt "14" ]; then
                     {
                        #Ubuntu 14 or latest
			sudo systemctl restart $package;sudo systemctl enable $package;
                        }
		fi
		}
	rm -f /tmp/cmk.deb
	fi
	}
elif [ "$OS" == "Amazon" ]; then
	{
	isinstalled=$(rpm -q $package)
	if [ ! "$isinstalled" == "package $i is not installed" ];then
		{
		iptables -I INPUT -p tcp -s 10.0.0.0/8 --dport 6556 -j ACCEPT
		yum makecache fast
		yum install xinetd -y
		sudo yum install wget -y
		sudo yum install -y http://$FileServer/uploads/check-mk-agent-1.4.0p18-1.noarch.rpm;
		wget http://$FileServer/uploads/check_mk -O /etc/xinetd.d/check_mk
		
		if [ "$AREL" -ge "2018" ]; then
			{
			#Amazone Linux 2018
			sudo service $package restart;
			}
		elif [ "$AREL" -le "2017" ]; then
                        {
                        #Amazone Linux 2014
                        sudo restart $package;
                        }
		fi
		}
	else 
		{
			echo "Package $package is already installed";
		}
	fi
	}
elif [ "$OS" == "CentOS" ]; then

	{
	isinstalled=$(rpm -q $package)
	if [ ! "$isinstalled" == "package $i is not installed" ];then
		{	
			iptables -I INPUT -p tcp -s 10.0.0.0/8 --dport 6556 -j ACCEPT
			sudo install wget -y
			sudo yum install -y http://$FileServer/uploads/check-mk-agent-1.4.0p18-1.noarch.rpm;
			wget http://$FileServer/uploads/check_mk -O /etc/xinetd.d/check_mk
			sudo systemctl enable $package;sudo systemctl restart $package;sudo restart $package;
		}
	else 
		{
			echo "Package $package is already installed";
		}
	fi
	}
else
	{
		echo "I'm sorry.. I had a hard time understanding the OS Platform" >&2;
		exit 1;
	}
fi

# END
