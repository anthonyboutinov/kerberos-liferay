#!/bin/bash
### 

if [[ ${BASH_VERSION:0:1} < 4 ]] ; then 
	echo "The script will not run in older versions of bash. Please, update bash to v4."
	exit
fi

echo "================================================================================"
echo "=                     Kerberos Server installation script                      ="
echo "=      by Anthony Boutinov (github.com/anthonyboutinov/kerberos-liferay)       ="
echo "=                                                                              ="
echo "=        This script is designed to run on CentOS 6 or 7 and Red Hat.          ="
echo "=      If you are running a different OS, please modify it accordingly.        ="
echo "================================================================================"
echo 

###

while true; do
    read -e -p "Do you want to install NTP and setup automatic time sync? (y/n) " -i "y" _ISONOPENVZ
    case $_ISONOPENVZ in
        [Yy]* ) ISONOPENVZ=""; break;;
        [Nn]* ) ISONOPENVZ="f"; break;;
        * ) echo "Please answer yes or no.";;
    esac
done

read -e -p "Enter DNS Domain (this will also be the KDC Realm name, in all caps): " -i "example.com" NAME
read -e -p "Enter KDC & Admin server FQDN: " -i "kdc" _SUBDOMENNAME

SUBDOMENNAME=$(echo $_SUBDOMENNAME| tr '[:upper:]' '[:lower:]')
NAMELOWER=$(echo $NAME| tr '[:upper:]' '[:lower:]')
NAMEUPPER=$(echo $NAME| tr '[:lower:]' '[:upper:]')

echo 
echo "Realm:            $NAMEUPPER"
echo "Address:          $NAMELOWER"
echo "KDC:              $SUBDOMENNAME.$NAMELOWER"
echo "Admin server:     $SUBDOMENNAME.$NAMELOWER"
echo 

read -s -e -p "Enter password for root/admin KDC principal: " ROOTKDCPASS
echo 
read -e -p "Enter name for normal KDC principal: " TESTUSERNAME
read -s -e -p "Enter password for $TESTUSERNAME: " TESTUSERPASS
echo 

###

function installNTP {
	echo
	echo "Installing NTP..."

	yum -y install ntp
	ntpdate 0.rhel.pool.ntp.org
	systemctl start  ntpd.service
	systemctl enable ntpd.service
}

if [ -n "$ISONOPENVZ" ]
then
	installNTP
fi
###

function installKRBSERVLIB {
	echo 
	echo "Installing krb5-server, krb5-libs, krb5-workstation..."
	yum -y install krb5-server krb5-libs krb5-workstation
}

installKRBSERVLIB

###

echo
echo "Configuring Kerberos KDC"

# In parameters: $1 -- NAMEUPPER, $2 -- NAMELOWER, $3 -- SUBDOMENAME
function krbconf {
cat << EOF
[libdefaults]
    default_realm = $1
    dns_lookup_realm = false
    dns_lookup_kdc = false
    ticket_lifetime = 24h
    forwardable = true
    udp_preference_limit = 1000000
    default_tkt_enctypes = des-cbc-md5 des-cbc-crc des3-cbc-sha1
    default_tgs_enctypes = des-cbc-md5 des-cbc-crc des3-cbc-sha1
    permitted_enctypes = des-cbc-md5 des-cbc-crc des3-cbc-sha1

[realms]
    $1 = {
        kdc = $3.$2:88
        admin_server = $3.$2:749
        default_domain = $2
    }

[domain_realm]
    .$2 = $1
     $2 = $1

[logging]
    kdc = FILE:/var/log/krb5kdc.log
    admin_server = FILE:/var/log/kadmin.log
    default = FILE:/var/log/krb5lib.log
EOF
}

krbconf $NAMEUPPER $NAMELOWER $SUBDOMENNAME > /etc/krb5.conf

# In parameter: $1 -- NAMEUPPER
function kdcconf {
cat << EOF
default_realm = $1

[kdcdefaults]
    v4_mode = nopreauth
    kdc_ports = 0

[realms]
    $1 = {
        kdc_ports = 88
        admin_keytab = /etc/kadm5.keytab
        database_name = /var/kerberos/krb5kdc/principal
        acl_file = /var/kerberos/krb5kdc/kadm5.acl
        key_stash_file = /var/kerberos/krb5kdc/stash
        max_life = 10h 0m 0s
        max_renewable_life = 7d 0h 0m 0s
        master_key_type = des3-hmac-sha1
        supported_enctypes = arcfour-hmac:normal des3-hmac-sha1:normal des-cbc-crc:normal des:normal des:v4 des:norealm des:onlyrealm des:afs3
        default_principal_flags = +preauth
    }
EOF
}

kdcconf $NAMEUPPER > /var/kerberos/krb5kdc/kdc.conf

# In parameter: $1 -- NAMEUPPER
function kadm {
cat << EOF
*/admin@$1    *
EOF
}

kadm $NAMEUPPER > /var/kerberos/krb5kdc/kadm5.acl

###

IPADDR=$(echo $(hostname -I))
PRIMARYNAMEPART=${NAMELOWER/%.*/}
# echo "$IPADDR $SUBDOMENNAME.$NAMELOWER $PRIMARYNAMEPART"
# echo "127.0.0.1   $PRIMARYNAMEPART"
echo "$IPADDR $SUBDOMENNAME.$NAMELOWER $PRIMARYNAMEPART" >> /etc/hosts
echo "127.0.0.1   $PRIMARYNAMEPART" >> /etc/hosts

###

echo
echo "Creating database... (this may take a couple of minutes)"
echo "After it's finished, you will need to give it a new password"

kdb5_util create -r $NAMEUPPER -s  
# здесь ввод пароля два раза

###

echo
echo "Creating root/admin principal and $TESTUSERNAME principal"

echo "add_principal -pw $ROOTPASS root/admin" | kadmin.local > /dev/null
echo "add_principal -pw $TESTUSERPASS $TESTUSERNAME" | kadmin.local > /dev/null

echo "ktadd -k /var/kerberos/krb5kdc/kadm5.keytab kadmin/admin" | kadmin.local > /dev/null
echo "ktadd -k /var/kerberos/krb5kdc/kadm5.keytab kadmin/changepw" | kadmin.local > /dev/null

###

echo
echo "Starting KDC & admin daemons"

# CentOS 7
systemctl start krb5kdc.service
systemctl start kadmin.service
systemctl enable krb5kdc.service
systemctl enable kadmin.service

# CentOS 6
/sbin/service krb5kdc start
/sbin/service kadmin start
echo "NEED TO SET UP TO START AUTOMATICALLY ON BOOT!"

###

echo
echo "Creating principal for KDC server"

echo "add_principal -randkey host/kdc.$NAMELOWER" | kadmin.local > /dev/null
echo "ktadd host/kdc.$NAMELOWER" | kadmin.local > /dev/null

###

echo
echo "Finished setting up Kerberos KDC! Default realm is $NAMEUPPER."