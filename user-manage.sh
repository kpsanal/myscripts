#!/bin/bash
##
##    User Management - Jump
##

NEW_USER=$1
GROUP=$2
NHOME="/home/$NEW_USER"

create_user(){
        adduser -q --gid $GROUP $NEW_USER --disabled-password
        read -p "Enter the SSH Public key:" PUBLIC_KEY
        mkdir $NHOME/.ssh/
        echo "$PUBLIC_KEY" > $NHOME/.ssh/authorized_keys
        chown $NEW_USER:$GROUP $NHOME/.ssh/authorized_keys
        chmod -R 600 $NHOME/.ssh
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
        }

if [ -z $NEW_USER ]
then
        {
                echo -e "\n\n\tUsage:\n\t\t$0 username [Optional: ADMIN Group]\n\n"
        }
else
        if [ -z $GROUP ]
        then
                {
                GROUP="100"
                create_user
                }
        else
                {
                # ADMIN Group with Sudo Access
                GROUP="116"
                create_user
                }
        fi
        2fa_enable
fi
