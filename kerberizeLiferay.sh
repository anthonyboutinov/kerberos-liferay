#!/bin/bash
### 

if [[ ${BASH_VERSION:0:1} < 4 ]] ; then 
	echo "The script will not run in older versions of bash. Please, update bash to v4."
	exit
fi

echo "================================================================================"
echo "=           Liferay Portal bundled with Tomcat kerberization script            ="
echo "=      by Anthony Boutinov (github.com/anthonyboutinov/kerberos-liferay)       ="
echo "=                                                                              ="
echo "=        This script is designed to run on CentOS 6 or 7 and Red Hat.          ="
echo "=      If you are running a different OS, please modify it accordingly.        ="
echo "=                                                                              ="
echo "=          Check if there are newer versions of software available             ="
echo "=       (if you wish to install Liferay IDE and Liferay Plugins SDK).          ="
echo "================================================================================"
echo 

###

read -e -p "Locate Tomcat directory inside Liferay in another Terminal tab, then write it down here (like /opt/liferay-X.X/tomcat-X.X.X): " TOMCATLOCATION

echo
read -e -p "You will now enter server.xml with vi editor. Please, read up on github.com/anthonyboutinov/kerberos-liferay what edits to perform here." EMPTYINPUT
vi $TOMCATLOCATION/conf/server.xml

###

echo
read -e -p "Enter DNS Domain: " -i "example.com" NAME
read -e -p "Enter KDC & Admin server FQDN: " -i "kdc" _SUBDOMENNAME

SUBDOMENNAME=$(echo $_SUBDOMENNAME| tr '[:upper:]' '[:lower:]')
NAMELOWER=$(echo $NAME| tr '[:upper:]' '[:lower:]')
NAMEUPPER=$(echo $NAME| tr '[:lower:]' '[:upper:]')

###

echo
echo "Installing krb5-workstation, httpd, httpd-devel, mod_auth_kerb..."

yum -y install krb5-workstation httpd httpd-devel mod_auth_kerb ant

###

echo
echo "Writing to httpd.conf"
echo "Include $TOMCATLOCATION/conf/mod_jk.conf" >> /etc/httpd/conf/httpd.conf
echo "Include /etc/httpd/conf/mod_kerb.conf" >> /etc/httpd/conf/httpd.conf

###

echo
echo "Writing to mod_kerb.conf"

# In parameter: $1 -- NAMEUPPER $2 -- NAMELOWER $3 -- SUBDOMENNAME
function modkerb {
cat << EOF
# New file for the configuration of the module "mod_auth_kerb" and Kerberos
ServerAdmin root@localhost
# The FQDN of the host server
ServerName $3.$2:80

# Find the location of the mod_auth_kerb and replace it there if it's not the same
LoadModule auth_kerb_module /usr/local/apache2/modules/mod_auth_kerb.so

<Location />
	AuthName "$1"
	AuthType Kerberos
	Krb5Keytab /etc/krb5lif.keytab
	KrbAuthRealms $1
	KrbMethodNegotiate On
	KrbMethodK5Passwd On
	require valid-user
</Location>
EOF
}

modkerb $NAMEUPPER $NAMELOWER $SUBDOMENNAME > /etc/httpd/conf/mod_kerb.conf

echo
echo "Installing mod_jk..."

cd /opt

# Update the link if necessary
TOMCATCONNECTORS="tomcat-connectors-1.2.40-src"
wget http://apache-mirror.rbc.ru/pub/apache/tomcat/tomcat-connectors/jk/$TOMCATCONNECTORS.tar.gz

tar -xvf $TOMCATCONNECTORS.tar.gz > /dev/null
rm -f $TOMCATCONNECTORS.tar.gz
cd $TOMCATCONNECTORS/native
./configure --with-apxs=$(echo $(which apxs)) --with-tomcat=$TOMCATLOCATION --with-httpd=$(echo $(which httpd)) --enable-api-compatibility
make
make install

cd /usr/lib64/httpd
mkdir logs

###

echo
echo "Writing to $TOMCATLOCATION/conf/mod_jk.conf"

# In parameter: $1 -- TOMCATLOCATION
function modjkconf {

# Edit this, if httpd located somewhere else
HTTDLOCATION="/usr/lib64/httpd"

cat << EOF
LoadModule jk_module $HTTDLOCATION/modules/mod_jk.so
JkWorkersFile $1/conf/workers.properties
JkLogFile $HTTDLOCATION/logs/mod_jk.log
JkLogLevel debug
JkLogStampFormat "[%a %b %d %H:%M:%S %Y]"
# JkOptions indicate to send SSL KEY SIZE,
JkOptions +ForwardKeySize +ForwardURICompat -ForwardDirectories
# JkRequestLogFormat set the request format
JkRequestLogFormat "%w %V %T"
JkMount / ajp13
JkMount /* ajp13
EOF
}

modjkconf $TOMCATLOCATION > $TOMCATLOCATION/conf/mod_jk.conf

###

echo
echo "Writing to $TOMCATLOCATION/conf/workers.properties"

function workersproperties {
cat << EOF
# Define 1 real worker named ajp13
worker.list=ajp13
worker.ajp13.type=ajp13
worker.ajp13.host=localhost
worker.ajp13.port=8009
worker.ajp13.lbfactor=50
worker.ajp13.cachesize=10
worker.ajp13.cache_timeout=600
worker.ajp13.socket_keepalive=1
worker.ajp13.socket_timeout=300
EOF
}

workersproperties $TOMCATLOCATION > $TOMCATLOCATION/conf/workers.properties

###

while true; do
    read -e -p "Do you want to install Liferay IDE (Eclipse)? (y/n) " _INSTALLIDE
    case $_INSTALLIDE in
        [Yy]* ) INSTALLIDE="t"; break;;
        [Nn]* ) INSTALLIDE=""; break;;
        * ) echo "Please answer yes or no.";;
    esac
done

if [ -n "$INSTALLIDE" ]
then

	echo
	echo "Installing wget..."
	yum -y install wget

	echo
	echo "Downloading Liferay IDE (Eclipse)..."

	# Please, edit this link, if you want a more recent version
	cd /opt
	wget http://downloads.sourceforge.net/project/lportal/Liferay%20IDE/2.2.2%20GA3/liferay-ide-eclipse-linux-x64-2.2.2-ga3-201501300730.tar.gz?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Flportal%2Ffiles%2FLiferay%2520IDE%2F2.2.2%2520GA3%2F&ts=1431351556&use_mirror=garr
	mv liferay-ide-eclipse-linux-x64-2.2.2-ga3-201501300730.tar.gz?r=http:%2F%2Fsourceforge.net%2Fprojects%2Flportal%2Ffiles%2FLiferay%20IDE%2F2.2.2%20GA3%2F liferay-ide.tar.gz
	tar -xvf liferay-ide.tar.gz > /dev/nul
	rm -f liferay-ide.tar.gz

fi

###

echo
while true; do
    read -e -p "Do you want to download Liferay Plugins SDK? (y/n) " _INSTALLSDK
    case $_INSTALLSDK in
        [Yy]* ) INSTALLSDK="t"; break;;
        [Nn]* ) INSTALLSDK=""; break;;
        * ) echo "Please answer yes or no.";;
    esac
done

if [ -n "$INSTALLSDK" ]
then

	echo
	echo "Installing development tools, ant, gcc, gcc-c++..."
	yum groupinstall "Development Tools"
	yum -y install gcc gcc-c++ ant

	echo
	echo "Downloading Liferay Plugins SDK..."

	# Please, edit this link, if you want a more recent version
	cd /opt
	wget http://downloads.sourceforge.net/project/lportal/Liferay%20Portal/6.2.3%20GA4/liferay-plugins-sdk-6.2-ce-ga4-20150416163831865.zip?r=http%3A%2F%2Fwww.liferay.com%2Fdownloads%2Fliferay-portal%2Favailable-releases&ts=1431353316&use_mirror=softlayer-ams
	mv liferay-plugins-sdk-6.2-ce-ga4-20150416163831865.zip?r=http:%2F%2Fwww.liferay.com%2Fdownloads%2Fliferay-portal%2Favailable-releases plugins.zip
	unzip plugins.zip > /dev/nul
	rm -f plugins.zip

	read -e -p "Enter this account's username to grant it privileges over /opt/liferay-plugins-sdk-6.2 folder: " USERNAME

	chown $USERNAME -R /opt/liferay-plugins-sdk-6.2

fi

###

while true; do
    read -e -p "Do you want to download kerberos-hook war file for Liferay Portal? (y/n) " _GETWARFILE
    case $_GETWARFILE in
        [Yy]* ) GETWARFILE="t"; break;;
        [Nn]* ) GETWARFILE=""; break;;
        * ) echo "Please answer yes or no.";;
    esac
done

if [ -n "$GETWARFILE" ]
then
	
	read -e -p "Where do you want to place the file (/opt/liferay-X.X.X/deploy)? " -i "/opt/liferay.../deploy" DOWNLOADLOCATION
	
	cd $DOWNLOADLOCATION
	wget https://github.com/anthonyboutinov/kerberos-liferay/blob/master/kerberos-hook-6.2.0.1.war?raw=true
	mv kerberos-hook-6.2.0.1.war?raw=true kerberos-hook-6.2.0.1.war
	
	echo
	echo "Rebooting Tomcat and Apache HTTPd..."
	$TOMCATLOCATION/bin/shutdown.sh > /dev/nul
	apachectl stop
	
# 	echo "Performing full compile of the policy after changing httpd_read_user_content's value (this may take up to a minute)..."
# 	setsebool -P httpd_read_user_content 1

	echo "Making httpd to be allowed to access/append/write etc to logs directory... [0% done]"
	grep httpd /var/log/audit/audit.log | audit2allow -M mypol > /dev/null
	semodule -i mypol.pp
	echo "Making httpd to be allowed to access/append/write etc to logs directory... [33% done]"
	grep httpd /var/log/audit/audit.log | audit2allow -M mypol > /dev/null
	semodule -i mypol.pp
	echo "Making httpd to be allowed to access/append/write etc to logs directory... [66% done]"
	grep httpd /var/log/audit/audit.log | audit2allow -M mypol > /dev/null
	semodule -i mypol.pp
	echo "Making httpd to be allowed to access/append/write etc to logs directory... [100% done]"
	
	apachectl start
	$TOMCATLOCATION/bin/startup.sh > /dev/nul
	echo
	echo "Finished with Liferay kerberization!"
	echo "Tomcat is rebooting. Liferay portal page should open automatically in a couple of minutes..."
	
else
	echo
	echo "Finished with Liferay kerberization!"
fi
