#!/bin/bash
### 

if [[ ${BASH_VERSION:0:1} < 4 ]] ; then 
	echo "The script will not run in older versions of bash. Please, update bash to v4."
	exit
fi

echo "================================================================================"
echo "=                     Kerberos Client installation script                      ="
echo "=          by Anthony Boutinov (github.com/anthonyboutinov/Kerberos)           ="
echo "=                                                                              ="
echo "=        This script is designed to run on CentOS 6 or 7 and Red Hat.          ="
echo "=      If you are running a different OS, please modify it accordingly.        ="
echo "================================================================================"
echo 

###

echo 
read -e -p "Enter realm domain name: " -i "example.com" DOMAINNAME
DOMAINNAME=$(echo $DOMAINNAME| tr '[:upper:]' '[:lower:]')

###

echo
echo "Transferring krb5.conf file from Kerberos server (remote machine) to local machine:"

read -e -p "Enter remote login: " -i "root" REMOTELOGIN
REMOTELOGIN="$REMOTELOGIN@$DOMAINNAME"

scp -r $REMOTELOGIN:/etc/krb5.conf /etc/krb5.conf

###

echo
read -s -e -p "Enter kadmin root/admin password: " KADMINPASS
echo

read -e -p "Enter host principal name (client) (domain name will be appended): " -i "host/client" CLIENT
CLIENT="$CLIENT.$DOMAINNAME"
echo "Resulting name: $CLIENT"

read -e -p "Enter host principal name (kdc): " -i "host/kdc" KDC
KDC="$KDC.$DOMAINNAME"
echo "Resulting name: $KDC"

###

echo "add_principal -randkey $CLIENT" | kadmin -p root/admin -w $KADMINPASS
echo "ktadd $KDC" | kadmin -p root/admin -w $KADMINPASS

###

echo
echo "Finished setting up Kerberos Client!"