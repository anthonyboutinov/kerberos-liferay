# kerberos-liferay
Kerberos setup and Liferay Portal (bundled with Tomcat) kerberization scripts.

These scripts are designed for easy and fast installation and configuration of Kerberos Server (KDC) on one machine and Kerberos Client on another machine, where Liferay Portal is located.

## Instructions

1. Download and run `kerberosKDC.sh` on one machine to configure Kerberos KDC.
2. Download and run `kerberosClient.sh` on another machine (where you have Liferay Portal) to configure Kerberos Workstation.
3. Download and run `kerberizeLiferay.sh` to install Apache HTTPd, configure it and Apache Tomcat, and perform Liferay Portal kerberization. The last can be done in two ways.
  1. You will be asked to let the script install Liferay IDE (Eclipse), if you want to customize Liferay hook.
  2. You will be asked to let the script download Liferay Plugins SDK (again, if you want to customize the hook).
  3. You will be asked if you want to simply download the war file from this repository and deploy it to Liferay Portal.

Minor instructions are embedded into script files themselves. This mostly includes updating download links to newer versions of applications if desired, or checking if paths are identical to what you have on your machines.

### Instructions for kerberizeLiferay.sh

#### Apache Tomcat configuration
When presented with edit screen of `$TOMCATLOCATION/conf/server.xml` file, make sure it looks like this (`maxHttpHeaderSize` and `tomcatAuthentication` are set properly):

```xml
…
    <!-- A "Connector" represents an endpoint by which requests are received
         …
         Define a non-SSL HTTP/1.1 Connector on port 8080
    -->
    <Connector port="8080" protocol="HTTP/1.1"
               connectionTimeout="20000"
               redirectPort="8443" URIEncoding="UTF-8"
               maxHttpHeaderSize="32768" />
…
    <!-- Define an AJP 1.3 Connector on port 8009 -->
    <Connector port="8009" protocol="AJP/1.3"
               redirectPort="8443" URIEncoding="UTF-8"
               tomcatAuthentication="false" />
…
```

--
Liferay Portal Kerberos-Hook is based on [Morgan Patou's one](http://www.dbi-services.com/index.php/blog/entry/kerberos-sso-with-liferay-61).
