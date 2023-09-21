---
id: solution-integrate
sidebar_position: 3
title: Integrate
---

# Integrate

## Standalone Process Designer Setup

### Version info
- IBM Content Platform Engine - 5.5.10.0
- IBM Content Navigator 3.0.13

### Prerequisites
- A [Java Runtime Environment](https://www.java.com/en/download/) (JRE 1.8 or newer)
- [Add Java to PATH](https://www.ibm.com/docs/en/b2b-integrator/6.0.2?topic=installation-setting-java-variables)
- Install the Filenet Content Manager CPE tools package from IBM Passport Advantage using the part number `M0CTDML`

### Setup Steps:

1. Creating a Workflow System and Connection Point within Filenet
    1. Open up and log into the acce console.
    2. Open the Object Store in which you want to store Workflow data.
    3. Click on _Administrative->Workflow_ System.
    4. Click New.
    5. Under _Table Spaces -> Data_, enter the tablespace where you want workflow files to be stored.
    6. Under _Workflow System Security Groups -> Administration Group_, enter the admin group you want to assign to the Workflow System. These two can be found in your filenet configuration (you can log into the database and see the tablespaces if needed).
    7. Continue through the steps adding Connection Point and Isolated Region names and enter the _Isolated Region Number_ (1 if it’s your first in this object store, and so on).
    8. If you wish, you can _Specify Isolated Region Table Space (Optional)_.
    9. Review all the details and click _Finish_.
    10. Navigate to _Workflow System->Connection Points_ to confirm that it was successfully created.

2. SSL Configuration (adding the site certificate into the jre keystore)
    1. Launch Chrome
    2. Navigate to the ACCE console
    3. Click on the Lock Icon on the left side of the url -> Connection is Secure -> Certificate is Valid -> Details -> Export...
    4. Export **full certificate chain** (usually the second option in Save as) and **change extension to .crt** instead of .cert
    run appropriate command to import it into your JRE keystore
      - Windows:
    `..\..\bin\keytool -import -keystore ..\..\lib\security\cacerts -file cpe_websphere_ssl_cert.crt`
      - Linux:
    `../../bin/keytool -import -keystore ../../lib/security/cacerts -file cpe_websphere_ssl_cert.crt`
    5. You should see an `added to keystore` message

3. Configuring and Launching the Process Designer
    1. Unzip the Process Designer zip file and all zip files within it for your platform.
    2. Navigate to: `<unzipped_folder>/cpetools-<platform>/peclient/`
    3. Open this folder in any text editor or IDE (ex. code .).
    4. Open:
      - `shell/cpetoolenv.sh` (Linux/Mac)
      - `batch/cpetoolenv.bat` (Windows)
    4. Set the `PE_CLIENT_INSTALL_DIR` to the full path of the `cpe_tools-<platform>` directory, i.e., `/Users/…/<unzipped_folder>/cpetools-linux`, beware of any spaces in the folder path.
    5. Open `config/WcmApiConfig.properties`.
    6. Set the `RemoteServerUrl`:
      - If you access the acce console at `<host_link>/acce/`, then confirm you can access the ping page at `<host_link>/peengine/IOR/ping`.
      - If you can get to this page, then your `RemoteServerUrl` is likely to be `<host_link>/wsi/FNCEWS40TOM`.
    7. Open a command line utility (i.e., Terminal [Mac], cmd [Windows]).
    8. Navigate (cd) to:
      - `<unzipped_folder>/cpetools-linux/peclient/shell` (Linux/Mac)
      - `<unzipped_folder>/cpetools-win/peclient/batch` (Windows)
    9. Run:
      - `sh ./pedesigner.sh <connection_point>` (Linux/Mac)
      - `pedesigner.bat <connection_point>` (Windows)
    10. Enter credentials used to login to the ACCE console.
    11. Process Designer should open up!
