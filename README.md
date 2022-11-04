# kerberos-liferay
Kerberos setup and Liferay Portal (bundled with Tomcat) kerberization scripts.

These scripts are designed for easy and fast installation and configuration of Kerberos Server (KDC) on one server and Kerberos Client on another server, where Liferay Portal is located.

## Instructions

Before running, inspect the contents of .sh files. Minor instructions are embedded into script files themselves. This mostly includes updating download links to newer versions of applications if desired, or checking if paths are identical to what you have on your machines.

<ol>
  <li>
    Download and run `kerberosKDC.sh` on one server to configure Kerberos KDC. You will be asked to
    <ol>
      <li>enter Kerberos realm name,</li>
      <li>set password for root/admin principal, and</li>
      <li>login-password pair for test principal.</li>
    </ol>
  </li>
  <li>
    Download and run `kerberosClient.sh` on another server (where you have Liferay Portal) to configure Kerberos Workstation. During this process you will be asked to
    <ol>
      <li>enter credentials for ssh session with the first server and</li>
      <li>enter FQDN for current (client) server.</li>
    </ol>
  </li>
  <li>
  Download and run `kerberizeLiferay.sh` to install Apache HTTPd, configure it and Apache Tomcat, and perform Liferay Portal kerberization.
    <ol>
      <li>First, you set `TOMCATLOCATION` variable,</li>
      <li>then you will enter vi editor with `$TOMCATLOCATION/conf/server.xml` file. Follow the instructions below (see section [*Apache Tomcat configuration*](https://github.com/anthonyboutinov/kerberos-liferay#apache-tomcat-configuration)).</li>
      <li>Enter KDC domain name and KDC's and admin server's FQDNs.</li>
      <li>You will be asked to let the script to install Liferay IDE (Eclipse), if you want to customize Liferay hook.</li>
      <li>You will be asked to let the script to download Liferay Plugins SDK (again, if you want to customize the hook).</li>
      <li>You will be asked if you want to simply download the war file from this repository and deploy it to Liferay Portal (this will restart HTTPd and Tomcat).</li>
    </ol>
  </li>
</ol>

After that, Liferay will be using Kerberos authentication protocol on **port 80**.

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
Liferay Portal Kerberos-Hook is based on [Morgan Patou's post](http://www.dbi-services.com/index.php/blog/entry/kerberos-sso-with-liferay-61) ([WebArchive mirror](https://web.archive.org/web/20141130083513/http://www.dbi-services.com/index.php/blog/entry/kerberos-sso-with-liferay-61)).
