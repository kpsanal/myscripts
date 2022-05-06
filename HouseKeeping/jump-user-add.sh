##              Create User in the Jump Server
##
##      Created: June 3, 2021   Author: Sethu Madhavan
##      License: GNU GPL v3
##      Note: ONLY Key Authentication & Forced 2FA with Google
##
#!/bin/bash

NEW_USER=$1
GROUP=$2
NHOME="/home/$NEW_USER"

create_user(){
        adduser -q --gid $GROUP $NEW_USER --disabled-password
        read -p "Enter the SSH Public key:" PUBLIC_KEY
        mkdir $NHOME/.ssh/
        echo "$PUBLIC_KEY" > $NHOME/.ssh/authorized_keys
        chown -R $NEW_USER:$GROUP $NHOME/.ssh
        chmod -R 700 $NHOME/.ssh
        }

2fa_enable()
        {
        cat > $NHOME/.enable_2fa.sh << EOF
        #!/bin/bash
        google-authenticator
        sed '/enable_2fa/d' -i $NHOME/.profile
        rm -f ~/.enable_2fa.sh
EOF
        chmod +x $NHOME/.enable_2fa.sh
        echo "source ~/.enable_2fa.sh" >> $NHOME/.profile
        chown $NEW_USER:$GROUP $NHOME/.enable_2fa.sh
        }


if [ -z $GROUP ]; then
        {
        # Unpreviledged user
        GROUP="100"
        }
    else
        {
        # ADMIN Group with Sudo Access
        GROUP="116"
        }
        fi

if [ -z $NEW_USER ]
then
        {
        echo -e "\n\n\tUsage:\n\t\t$0 <username> <Optional: ADMIN Group>\n\n"
        }
else
        create_user
        2fa_enable
fi
