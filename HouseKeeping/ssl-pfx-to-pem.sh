#!/bin/bash
#  SSL PFX to PEM Converter
#
clear;
PFX=$1
DN=`echo $PFX | cut -d'.' -f1`
ICA=$2
ICA="${ICA:=$DN/$DN-ca.crt}"

converter () {
        mkdir $DN
        rm $DN/*

        openssl pkcs12 -passout pass:"$PASS" -in $PFX -out "$DN/$DN"-ca.crt -cacerts -nokeys -chain -password pass:$PASS

        if [ $? == 0 ]; then
                {
                openssl pkcs12 -passout pass:"$PASS" -in $PFX -nocerts -nodes -out "$DN/$DN"-enc.key -password pass:$PASS
                openssl pkcs12 -passout pass:"$PASS" -in $PFX -clcerts -nokeys -out "$DN/$DN".crt -password pass:$PASS
                openssl rsa -passin pass:"$PASS" -in "$DN/$DN"-enc.key -out "$DN/$DN".key

                # Remove junky details
                #sed -i '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/d' $DN/$DN*

                # Create Cert Chain
                cat "$DN/$DN".crt "$DN/$DN".key "$ICA" > "$DN/$DN"-chain.crt

                echo -e "\n\nCert Files are Generated!! - $PWD/$DN\n"
                ls -l "$DN/" | grep -v total

                # Verify the Cert
                echo -e "\nVerifying the Certs.."
                openssl x509 -in "$DN/$DN".crt -text -noout | egrep 'Not Before|Not After|Subject:|DNS'
                echo -e "\n"

                exit 0;
                }
        else
                {
                        rm -rf $DN
                        echo -e "\n"
                        exit 1;
                }
        fi

        }


if [ -z $PFX ] && [ -f $PFX ]; then
        {
                echo -e "\n./ssl-converter.sh <cert.pfx>\n"
        }
else
        {
        echo -e "\nGenerating Certificates from $PFX...\n"
        read -p "Enter the Pass Key: " PASS

        converter
        }
fi
