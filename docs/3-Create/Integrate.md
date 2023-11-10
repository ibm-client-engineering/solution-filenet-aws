---
id: solution-integrate
sidebar_position: 3
title: Integrate
---

# Integrate
## Workflows

### Setup Components

#### Standalone Process Designer

##### Version info
- IBM Content Platform Engine - 5.5.11.0
- IBM Content Navigator 3.0.14

##### Prerequisites
- A [Java Runtime Environment](https://www.java.com/en/download/) (JRE 1.8 or newer)
- [Add Java to PATH](https://www.ibm.com/docs/en/b2b-integrator/6.0.2?topic=installation-setting-java-variables)
- Install the Filenet Content Manager CPE tools package from IBM Passport Advantage using the part number `M0CTDML`

##### Setup Steps

###### Creating a Workflow System and Connection Point within Filenet
    1. Open up and log into the acce console.
    2. Open the Object Store in which you want to store Workflow data.
    3. Click on _Administrative->Workflow_ System.
    4. Click New.
    5. Under _Table Spaces -> Data_, enter the tablespace where you want workflow files to be stored. &emsp;&emsp; _Note: see [Create Databases](https://ibm-client-engineering.github.io/solution-filenet-aws/Create/solution-deploy/#create-databases) for the tablespaces configuration, including their names._
    6. Under _Workflow System Security Groups -> Administration Group_, enter the admin group you want to assign to the Workflow System. These two can be found in your filenet configuration within the CR. &emsp;&emsp; _Note: see [Deploying CR](https://ibm-client-engineering.github.io/solution-filenet-aws/Create/solution-deploy/#deploying-cr). The admin group is specified under_ `initialize_configuration: ic_ldap_admins_groups_name` in the CR.
    7. Continue through the steps, adding Connection Point and Isolated Region names and enter the _Isolated Region Number_ (1 if it’s your first in this object store, and so on).
    8. If you wish, you can _Specify Isolated Region Table Space (Optional)_.
    9. Review all the details and click _Finish_.
    10. Navigate to _Workflow System->Connection Points_ to confirm that it was successfully created:

    ![](https://media.github.ibm.com/user/436100/files/9fa61a24-ae0d-4cf1-8b49-ca529857c829)

###### SSL Configuration (adding the site certificate into the jre keystore)
    1. Launch [Google Chrome](https://www.google.com/chrome/)
    2. Navigate to the ACCE console
    3. Click on the following- 
    
    - The _Lock Icon_ on the left side of the url:
    ![](https://media.github.ibm.com/user/436100/files/dfb9f7d5-12b9-42ee-8ced-376e2772ac48)

    - _Connection is secure_:
    ![](https://media.github.ibm.com/user/436100/files/e0855502-5992-4a16-9e66-e061f298a4e6)

    - _Certificate is valid_, _Details_ and then _Export..._:
    ![](https://media.github.ibm.com/user/436100/files/857a7863-5d60-4822-acea-b7d111065669)

    4. Export **full certificate chain** (usually the second option in Save as) and **change extension to .crt** instead of .cert:

    ![](https://media.github.ibm.com/user/436100/files/0b848a56-7cd9-43bb-b44c-32dc49fe35b5)

    5. Run the appropriate command to import it into your JRE keystore (keystore tool is found in the JAVA HOME directory under the bin folder)
      - Windows:
    `..\..\bin\keytool -import -keystore ..\..\lib\security\cacerts -file cpe_websphere_ssl_cert.crt`
      - Mac/Linux:
    `../../bin/keytool -import -keystore ../../lib/security/cacerts -file cpe_websphere_ssl_cert.crt`
    6. When prompted with _Trust this certificate? [no]_, respond with _yes_
    7. You should see an `added to keystore` message

:::note
    _Note:_
    If you are importing a key again, you may encounter the following error: &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;
    `keytool error: java.lang.Exception: Certificate not imported, alias <mykey> already exists`

    In which case you must delete the old key before importing the new one. Do so by running the following command with administrator priviledges (On Windows, run cmd as an Administrator. On Mac/Linux prepend `sudo` to the following command):&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;
    `keytool -delete -keystore ../lib/security/cacerts -alias mykey`
:::

###### Configuring and Launching the Process Designer
    1. Unzip the Process Designer zip file and all zip files within it for your platform. Beware that on Windows, unzipping the folders leads to a slightly different folder structure by default- there will be two peclient folders, one inside another. This can be 'fixed' by moving the one with the content into its parent.
    2. Navigate to: `<unzipped_folder>/cpetools-<platform>/peclient/`
    3. Open this folder in any text editor or IDE (ex. code .).
    4. Open:
      - `shell/cpetoolenv.sh` (Linux/Mac)
      - `batch/cpetoolenv.bat` (Windows)
    4. Set the `PE_CLIENT_INSTALL_DIR` to the full path of the `cpe_tools-<platform>` directory, i.e., `/Users/…/<unzipped_folder>/cpetools-linux`, beware of any spaces in the folder path.
    5. Open `config/WcmApiConfig.properties`.
    6. Set the `RemoteServerUrl`
      - If you access the acce console at `<host_link>/acce/`, then confirm you can access the ping page at `<host_link>/peengine/IOR/ping`:
      ![](https://media.github.ibm.com/user/436100/files/b287ddce-8d76-44a8-a848-b01e06184755)

      - If you can get to this page, then your `RemoteServerUrl` is likely to be `<host_link>/wsi/FNCEWS40TOM`. Check that you can also reach this page. If successful, it should display an xml document like so:
      ![](https://media.github.ibm.com/user/436100/files/ff515d36-8ec7-4c9f-b7c9-0a3bcbf02907)
      

    7. Open a command line utility (i.e., Terminal [Mac], cmd [Windows]).
    8. Navigate (cd) to:
      - Windows: `<unzipped_folder>/cpetools-win/peclient/batch`
      - Mac/Linux: `<unzipped_folder>/cpetools-linux/peclient/shell`
    9. Run:
      - Windows: `pedesigner.bat <connection_point>`
      - Mac/Linux: `sh ./pedesigner.sh <connection_point>`
    10. Enter credentials used to login to the ACCE console.
    11. Process Designer should open up!

#### Enabling Workflow Tab on Content Navigator

##### Prerequisites
- Workflow system and connection point have been created via the acce console in Object Store X (OSX)
- A repository has been setup within the Navigator

##### Configuration Steps
1. Open the Navigator
2. Navigate to *Administration->Repositories->OSX* (double click)
3. Click *Connect*
![](https://zenhub.ibm.com/images/649c3ae08710884b790df62c/7ed9e621-9c62-44b4-a3cb-38db5f11db1e)
4. Navigate to *Configuration Parameters -> Workflow Connection Point -> WF_CON_POINT_NAME* (for this repo we want to use this connection point):
![](https://zenhub.ibm.com/images/649c3ae08710884b790df62c/fb8d266a-371d-4fa4-acc8-938aaf006a46)
4. Click *Save and Close*
5. Navigate to *Administration->Desktops->icn_desktop* (default one)
6. Double check that the default repo matches OSX:
![](https://zenhub.ibm.com/images/649c3ae08710884b790df62c/4f2616a6-7c3c-4c5b-aae6-6ec358a484c9)
7. Navigate to *Layout->Check Work*:
![](https://zenhub.ibm.com/images/649c3ae08710884b790df62c/2376c113-0a9c-4f91-8380-5c0e2180e6de)
8. Navigate to *Workflows->Select OSX repo under Repository*:
![](https://zenhub.ibm.com/images/649c3ae08710884b790df62c/b6de3c23-f814-44a1-88c5-dcee6bc45e5f)
9. Select ApplicationSpace DefaultApplication and add it to the Selected Application Spaces:
![](https://zenhub.ibm.com/images/649c3ae08710884b790df62c/01bdc0b2-7d6e-4a2c-a75c-8ab6f4dd272d)
![](https://zenhub.ibm.com/images/649c3ae08710884b790df62c/3cf30464-de1e-4be5-9f14-c3542e2eaee5)
10. Click *Save and Close* and *Refresh*
11. You should see the Work tab (with in-baskets, if you have created and committed them via the Process Designer):

&emsp;&emsp;&emsp;&emsp;&emsp;
![](https://zenhub.ibm.com/images/649c3ae08710884b790df62c/6fc830ea-081b-4442-ad41-4c0a3e311ddc) 
&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;
![](https://zenhub.ibm.com/images/649c3ae08710884b790df62c/222bbe90-5145-40dd-8ddb-1062f8d78305)


### Creating Workflows

#### Claim Filing & Processing

The following workflow was demonstrated and then subsequently recreated and tested in Traveler's environment. It is a sample workflow for processing a claim application. We expanded on this by triggering it via a document upload using a subscription created in the acce console, which we will also mark as an initiating attachment to automatically include it in the triggered workflow (see below).

Workflow preview:
![](https://media.github.ibm.com/user/436100/files/4465abd7-143d-4385-8050-ee2a57a91bb7)

![](https://media.github.ibm.com/user/436100/files/0e65b54f-53bf-4f68-861b-18682b2608a7)

Workflow download:

[ClaimApplication.pep.zip](https://github.ibm.com/ibm-client-engineering/solution-filenet-aws/files/1242809/ClaimApplication.pep.zip)

#### Using Web Services

- In order to enable pasting wsdl partner links, navigate to _View -> Configuration_:
![](https://media.github.ibm.com/user/436100/files/db04cbaf-6cdd-439e-9310-38b6e2d594b6)

- Right click on the connection point and click _Properties..._: 
![](https://media.github.ibm.com/user/436100/files/bb20e3ed-ad22-4927-9bac-531eec0f55e1)

- Under _Web Services_, check _Enable Process Designer to enter WSDL links without browsing for Web services_:
![](https://media.github.ibm.com/user/436100/files/95c4e89d-fabc-41d0-85ec-a51fe141a1b5)

- Now you can paste links in _Workflow Properties_ under _Web Services_ in the _Partner Links_ section: 
![](https://media.github.ibm.com/user/436100/files/29c67c90-2903-4f98-92cb-8a3d0ad3dd26)

- Next, open up the Palette Menu and check _Web Services Palette_:
![](https://media.github.ibm.com/user/436100/files/7a174e99-650e-4a98-8860-f368ba4eb496)

- Now you can drag in _Invoke_ and select the created _Partner Link_ as well as the desired _Operation_:
![](https://media.github.ibm.com/user/436100/files/719a4799-369b-4e6b-b09a-ec76c3e24a78)

Note that for web services that require SSL (ex. _https://..._), you must add a secret containing the certificate to the trusted_certificate_list in the CR.

#### Initiating Attachments

Initiating attachments are attachments to Workflows that automatically get incorporated into them on upload, via a Subscription that triggers a workflow on Document Creation.

##### Creating a Subclass (optional)

If desired, you can create a subclass of an exisitng one to use as a more specific type. This can provide finer granularity when, for example, triggering workflows.


- Within the acce console, navigte to your choice of object store, go to _Classes_ under _Data Design_ and double click on a class you would like to form a subclass for. Next, click on _Actions_ and _New Class_:
![](https://media.github.ibm.com/user/436100/files/6374e1f9-7a2e-46ec-9ca0-5250ffdcd8ea)

- Enter a name and description:
![](https://media.github.ibm.com/user/436100/files/6a4aad75-72ae-46c0-8d5c-04c90fb04096)

- Click _Finish_:&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;
![](https://media.github.ibm.com/user/436100/files/cc0ab9b9-380f-4701-91ec-387615d123f2)

##### Creating the Subscription
- In the acce console under your choice of object store, navigate to _Events, Actions, Processes_ and then to _Subscriptions_:
![](https://media.github.ibm.com/user/436100/files/a8d51fa1-55e2-4640-a5ef-68bbf59a4d1f)

- Click _New_ and enter a name and description:
![](https://media.github.ibm.com/user/436100/files/298624d4-42a4-4a91-a864-d9c9e89dc50f)

- Specify the class (and optionally subclass) you would like to subscribe to:
![](https://media.github.ibm.com/user/436100/files/714ebd0f-246e-4d54-a576-56e4bcbd45c0)

- Check _Create a workflow subscription_ to allow this subscription to trigger a workflow:
![](https://media.github.ibm.com/user/436100/files/e51cc792-63ef-489e-9eba-ebcdc5f723a0)

- Select the events you would like to trigger the workflow. _Creation_ of a document signifies a document upload:
![](https://media.github.ibm.com/user/436100/files/e3158b7a-0eeb-43a4-b50a-76f0a48d1883)

- Specify which Workflow you would like this subscription to trigger:
![](https://media.github.ibm.com/user/436100/files/e1b73b54-2bcf-48b8-b992-94dc940f5907)

- Optionally map properties from the uploaded document (_Property name_) to the Workflow (_Data field name_): 
![](https://media.github.ibm.com/user/436100/files/1c47382e-f8b2-4f32-b001-03af611448b2)

- Ensure the subscription is enabled and if you would like, include subclasses:
![](https://media.github.ibm.com/user/436100/files/72fdeb48-fbf6-40d8-935f-1c4fdae3ae7c)

- Review the details and click _Finish_:&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;
![](https://media.github.ibm.com/user/436100/files/73330507-6e63-4524-a224-45e5cfb928ec)
![](https://media.github.ibm.com/user/436100/files/bb803613-3dd6-4134-8272-c40790343a2d)

##### Workflow Init Attachment

- Under _Workflow Properties_ in the _Attachments_ tab, create an attachment by double clicking under the _Name_ field, typing a name and pressing Enter:
![](https://media.github.ibm.com/user/436100/files/75ca2f4b-f3f5-4aec-ab24-f5c05553aed1)

- On the right sidebar, mark this as the _Initiating attachment_ by clicking the following icon, which should then appear left of the attachment name:&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;
![](https://media.github.ibm.com/user/436100/files/c9a35503-02b8-44c1-bec0-7da6611ba876)
&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;
![](https://media.github.ibm.com/user/436100/files/33d603f9-6313-4a6f-9036-10d4ad9e82e2)

- From the palette menu, drag in a component node:
![](https://media.github.ibm.com/user/436100/files/83dabcd3-90e6-4dbb-b881-cbce049fb45f)

- Configure this component by selecting an operation to extract information from the uploaded attachment, such as its given title, for example, which corresponds to symbolicPropName:
![](https://media.github.ibm.com/user/436100/files/320f420c-2c6d-454a-8203-4a55799f3edf)

This then populates the return value, which can be used elsewhere in the Workflow as desired

## Synchronous/Asynchronous Replication in FileNet

### Creating an Advanced Storage Device

Advanced Storage Devices are attached to Advanced Storage Areas and will be the devices used for replication. To create an Advanced Storage Device, log into the Administrative Console for Content Platform Engine and select the Object Store you want to use.

![FileNet Replication Object Store Select.png](https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/6daf8c2c-2690-475b-9d7b-ec02da646a6d)

Once inside the Object Store, navigate to Administrative -> Storage -> Advanced Storage -> Advanced Storage Devices. Once inside the Advanced Storage Devices folder, you should see several different devices such as Azure Blog, File System, OpenStack, and Simple Storage Service (S3).

![FileNet Replication Advanced Storage Area Devices Location.png](https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/e8bb5ffd-55c1-49cc-9e1e-c9d52ec38363)

Before creating another Advanced Storage Device, there should already be a File System Storage device. This device was automatically configured during the initial FileNet installation. Let’s go to the File System Storage Device folder and verify.

![FileNet Replication Adv Storage File system Storage Device.png](https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/a17a8d33-78d3-49c8-99c9-b99a7038da63)

This storage is an AWS Elastic File Share (EFS) storage Persistent Volume (PV), and it is being attached to the pod FileNet is running on. In the image above we can see where this PV is mounted under "Root Direct Path". Also, because this device is using EFS, we get all the resilience that comes standard with AWS EFS. We will be using this device later in an Advanced Storage Area.

Now let’s create another Advanced Storage Device. We will be setting up an S3 Bucket as another Advanced Storage Device. To do this, in the same Advanced Storage Devices folder you should see another folder named Simple Storage Service (S3) Devices. Once there click on the "New" button to create a new S3 Advanced Storage Device.

![FileNet Replication Adv Storage S3 Location.png](https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/d1edfc83-5ce6-4994-97c1-c06a0fb49b4f)

Next, we will be prompted to enter a display name for our S3 device in FileNet. This does not have to be the same name as your actual S3 bucket. This will be the device name within FileNet. Fill this out and select "Next".

![FileNet Replication Adv Storage S3 Name.png](https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/a39b88a0-910a-4af5-a060-5b011e190a99)

On the next page, enter the details for your user Key ID, Secret Access Key, and the S3 bucket details. Then click "next".

![FileNet Replication Adv Storage S3 setup.png](https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/bad61b23-e7fe-4e87-81a9-6236b5d7e21f)

The following page will display all your selected options and entered values for the S3 configuration. Validate the information and if everything looks correct select "Finish". FileNet will then try to connect to that S3 bucket. When it successfully connects you should see a confirmation message.

![FileNet Replication Adv Storage s3 Confirmation.png](https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/ef072216-3d76-4a5c-9343-c411f7eb12b1)

### Creating an Advanced Storage Area

Once we have connected Advanced Storage Devices to FileNet, we can create an Advanced Storage Area. Advanced Storage Areas handle how data is managed, replicated, and configured on Advanced Storage Devices. So, we associate one or more Advanced Storage Devices to an Advanced Storage Area and the Advanced Storage Area will manage those Advanced Storage Devices such as S3, EFS, etc.

Now let’s create an Advanced Storage Area. Within the same Object Store you created your Advanced Storage Devices, navigate to Administrative -> Storage -> Advanced Storage -> Advanced Storage Areas. Once there select "New".

![FileNet Replication Adv Storage Area Location.png](https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/52a9f635-20a4-48a1-a95e-55f4c8028a4f)

The next screen will prompt us for a name for the Advanced Storage Area. Enter any name that you like and then select "next".

![FileNet Replication Adv Storage Area Name.png](https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/13f54367-03a5-49c3-a459-b660a1300213)

The next screen will ask some general questions about the Advanced Storage Area configuration. You should see an "Encryption Method" option. Set "Encryption Method" to disabled and leave the other settings default. Then select "next".

![FileNet Replication Adv Storage Area Configuration.png](https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/f8865d1b-4214-4f62-a4a5-1d3bb2246a83)

The next page will ask you what Advanced Storage Devices you want to add to the Advanced Storage Area. Advanced Storage Area refers to Advanced Storage Devices as "Replicas". In the section "Creating an Advanced Storage Device". There were two Advanced Storage Devices. One was an EFS File System Storage device that came preinstalled with the FileNet installation and another S3 Advanced Storage Device we added. Both should appear in the area named "Available Storage Replication Devices". Select the boxes next to those devices and a checkmark should appear.

Right above that option you should see "Required Synchronous Devices". This is where we set how many synchronous devices are required for a successful document upload. FileNet must write synchronously to this specific number of devices for the upload to complete and be successful. For now, we can put the value "1" here.

![FileNet Replication Adv Storage Area Devices.png](https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/1e8ccc0d-7813-4620-bd00-551a23748c22)

Keep selecting next and leaving all options default until you get to the Summary page. You will get a warning about not setting a storage policy. We can always set that later. Click "OK" on the warning. The Summary page displays all your configuration options. If everything looks correct click "Finish" at the top.

![FileNet Replication Adv Storage Area Confirmation.png](https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/7f6bb3fc-688d-4a4a-a58a-aebe81b1c17b)

You should now see the newly created Advanced Storage Area in the list.

![FileNet Replication Adv Storage Area List.png](https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/92c815f7-c5e6-487b-83b3-3c974b55cc46)

### Configuring FileNet Replication

Once we have created an Advanced Storage Area and have attached Advanced Storage Devices, we can now configure the replication within that Advanced Storage Area. To configure the replication, navigate to Administrative -> Storage -> Advanced Storage -> Advanced Storage Areas. Here we should see the Advanced Storage Area we created in the previous section. Click on the name of the Advanced Storage Area.

![FileNet Replication Adv Storage Area.png](https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/7421f1ea-5daf-474e-9283-257e5a47f5b4)

Once you clicked on the Advanced Storage Area, the page should now display the configuration settings for that Advanced Storage Area. Click on the "Devices" Tab.

![FileNet Replication Adv Storage Area Device Settings.png](https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/fd71e0dc-6288-407c-865f-671a78ffed18)

There will be several settings here but let’s start with "Maximum synchronous devices" and "Required synchronous devices". These settings act as an upper and lower limit on the number of synchronous devices written to when a document is uploaded. The "Maximum synchronous devices" tells FileNet that, when possible, write to this specified number of devices. "Required synchronous devices" tells FileNet that it must write to this specified number of devices for the upload to be successful. You can see how this creates a type of range for the synchronous replication.

![FileNet Replication Adv Storage Area Min Max synch devices.png](https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/7d8d73a2-d018-4916-8c1e-4fabddae3730)

Now let’s configure the replication for the individual devices in the Advanced Storage Area. In the same page you see a box named "Device Connections". In this box you should see the Advanced Storage Devices connected to this Advanced Storage Area. We should see the devices that we added in the previous sections. To the right of each of these devices, we should see an option called "Default Synch Type".

![FileNet Replication Adv Storage Area Settings Default Synch Type.png](https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/2e3f674f-f502-4be2-ba4c-3e13bbeb4554)

This option controls the device replication priority and type. There are three Default Synch Types:

- Primary Synchronous - They are the primary, priority devices that FileNet will try to write synchronous operations to.
- Secondary Synchronous - If FileNet has exhausted all devices marked "Primary Synchronous", FileNet will then start using devices marked as "Secondary Synchronous" for synchronous write operations.
- Asynchronous - Devices with this type are always written to asynchronously and are not part of synchronous write operations.
  
This logic is further demonstrated in the following diagram:

![FileNet Replication Flow Diagram.png](https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/722f3cad-6dc4-4e22-b6cf-fcfbdb828a37)

**_NOTE: This diagram is meant to illustrate Default Synch Type priority and logic. This diagram does not take into account settings like maximum number of synchronous devices, how FileNet handles extra storage devices, or other FileNet factors and settings._

### Asynchronous replication

_Synchronous replication is discussed in the previous section [Configuring FileNet Replication](#configuring-filenet-replication)._

Content can also be written to replicas asynchronously with the content replication request sweep. Asynchronous replication is used under the following conditions:

- A storage device connection for a replica is explicitly configured for asynchronous replication. 
- If the maximum number of synchronous replicas has already been reached, but there are other primary or secondary designated replicas available, then, for performance purposes, the advanced storage area writes asynchronously to the remaining replicas.
- A synchronous write attempt to a replica fails. For example, if a primary replica fails, but the required number of primary replicas is satisfied, the advanced storage area places the write request to the failed replica in the replication sweep queue. The replication queue sweep writes the content after the failed replica is restored.
  
We mentioned that content is written asynchronously with content replication request sweeps. Sweeps are types of background jobs that run within FileNet. Once an object meets a configured criteria, the sweep performs an action on the object. There are several types of Sweeps in FileNet, and you can even create custom Sweeps. But for replication, this task is handled by content replication request sweeps. Content replication request sweeps are a type of Queue Sweep. Once FileNet has determined an asynchronous replication task, content replication request sweeps will try to write asynchronously to the replicas that meet the conditions that we previously discussed. Depending on factors within FileNet, content replication request sweeps may try to carry out that asynchronous write immediately or it might put it in a queue to be processed later. There are many factors that might cause the asynchronous job to be put in a queue, such as capacity, device availability, scheduling and so on.

Now that we have discussed the role of Sweeps in FileNet and how asynchronous write operations are handled by content replication request sweeps, let’s go into the Admin Console and view content replication request sweeps. Withing the Admin Console, select the Object Store that you used to create you Advanced Storage Area and Devices. Once inside that Object Store, navigate to Sweep Management -> Queue Sweeps -> Content Replication Sweep.

![FileNet Replication Content Replication Sweep Location.png](https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/7986557f-b186-42f4-952a-faf5f05c65d4)

Once here, we can configure how the Content Replication Sweep runs. For instance, we can set a schedule for the Content Replication Sweep. If we only want asynchronous write operations to occur at certain times of the day, we can set that here.

![FileNet Replication Content Replication Sweep Scheduling.png](https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/4f4232c7-b71d-4141-b506-77b6daee02d7)

Asynchronous jobs waiting to be executed by the Content Replication Sweep remain in the "Queue Entries" within the Content Replication Sweep. This queue shows upcoming asynchronous write operations along with other information such as status, failure count, etc. This information can be found by selecting the Queue Entries" tab within the Content Replication Sweep.

![FileNet Replication Content Replication Sweep Queue Entries.png](https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/3d63eac2-5d83-4512-a782-a6ae80a6d070)

### Testing Synchronous/Asynchronous Replication in FileNet

To test our synchronous/asynchronous configurations we can upload a document to FileNet. Withing the Admin Console, select the Object Store that you used to create you Advanced Storage Area and Devices. Then navigate to Browse. Within browse there will be a folder called "Root Folder". We can upload a document here or create another folder and upload it there. For our testing, lets upload to the Root Folder. Click on the Root Folder to enter. Once inside the Root Folder Select the "Actions" dropdown and select "New Document".

![FileNet Replication Content Replication Test Location.png](https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/f6380fcb-4bba-4f24-98c6-de614b44d6ae)

Give a name to the document and select "next".

![FileNet Replication Test Name.png](https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/24500f87-83c3-469f-a0ac-3565603a8aec)!

We will now need to add content to the document. To add a file, click "Add" in the "Content Elements". A pop-up window should appear named "Add Content Element". Add any file here and then select "Add Content" button on the bottom. The file we selected should appear in the Content Elements. Then select "Next".

![FileNet Replication Test Add Content.png](https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/db4bb1f6-677c-4497-8260-6909324a17cc)
![FileNet Replication Test Add Content page.png](https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/aad8b52f-5238-49d3-a133-f862374d7d4c)

Keep selecting next and leaving all settings default until you get to the "Advanced Features" page. Here we need to select the Advanced Storage Area we created in the previous section. Once we have selected the storage area, select "next".

![FileNEt Replication Test Storage Area Selection.png](https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/75f27860-e33a-4c5b-9f25-12ccef025b21)

The next page will be the summary page. The Summary page displays all your configuration options. If everything looks correct click "Finish" at the top.

You can now check your storage devices to verify the document was uploaded. Asynchronous writes may have the appearance of synchronous writes at times. This is because there is nothing like a schedule, capacity, or other limiting configurations that would cause the asynchronous write operation to be put into the queue. So, the content replication request sweep immediately executes the asynchronous write operation.


## Event Actions

### Slack Connector

#### Building and Pushing the Image

##### Prerequisites
- [Docker](https://www.docker.com/)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- A [Slack](https://slack.com/) account with admin access to a workspace
- Clone the [filenet-slack-connector](https://github.ibm.com/TechnologyGarageUKI/filenet-slack-connector) repo

##### Staging
- Download the slack connector image by running: (or follow repo instructions to build the image w/ Docker)
  - `curl -O https://publicimages.s3.us-east.cloud-object-storage.appdomain.cloud/slack-connector-ibm.tar.gz`
- For the following steps, refer to [Pushing a Docker Image (Amazon)](https://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-push-ecr-image.html) as needed
- Stage the image in your environment. One way to do this is Using *docker* & *aws cli*:
  - `docker import /path/to/exampleimage.tgz`
  - Retreive an authentication token & authenticate the docker client to your registry
    - `aws ecr get-login-password --region region | docker login --username AWS --password-stdin aws_account_id.dkr.ecr.region.amazonaws.com`
  - If you haven't already, [create a repository in Amazon ECR](https://docs.aws.amazon.com/AmazonECR/latest/userguide/getting-started-cli.html#cli-create-repository):
    - `aws ecr create-repository \
      --repository-name my-repository \
      --image-scanning-configuration scanOnPush=true \
      --region region`
  - Tag your image with the Amazon ECR registry
    - `docker tag <local-image-id> aws_account_id.dkr.ecr.us-west-2.amazonaws.com/my-repository:tag`
  - Push the image
    -  `docker push aws_account_id.dkr.ecr.us-west-2.amazonaws.com/my-repository:tag`

#### Configure Slack App, Environment Variables

##### Slack Setup
- [Navigate](https://api.slack.com/apps?new_app=1) to create a new app ![](https://zenhub.ibm.com/images/649c3ae08710884b790df62c/631b2d58-abda-4ced-bf89-a72c5a27194d)
- Once the app is created, open it (click on it) and go to *Incoming Webhooks*
![](https://zenhub.ibm.com/images/649c3ae08710884b790df62c/b9c85c5d-d77e-43f2-9b77-56c593155ffb)
  - Activate incoming webhooks:
![](https://zenhub.ibm.com/images/649c3ae08710884b790df62c/4d194d14-eb67-4870-838e-395c80d045a4)
  - Add one to your workspace:
![](https://zenhub.ibm.com/images/649c3ae08710884b790df62c/5fa104a4-432a-4b6b-b2e5-dd07a6043e81)  
- Navigate to *OAuth & Permissions*
![](https://zenhub.ibm.com/images/649c3ae08710884b790df62c/f5b84bfd-0a88-4e6d-8779-30c63b841ebc)
  - Copy the *Bot User OAuth Token*
![](https://zenhub.ibm.com/images/649c3ae08710884b790df62c/f62e6ee6-4145-4857-b484-f8a878a35117)
- On the same page, add OAuth scopes for *incoming-webhook*, *chat:write* and *channels:read*
![](https://zenhub.ibm.com/images/649c3ae08710884b790df62c/6d8e90ce-15db-47cd-9260-9ae4cba0566b) 
- Go to your slack channel and invite the bot to it:
  - `/invite @BOT_NAME`

##### Environment Variables
- The yaml files are found under the k8s folder of your project directory
  - secret.yaml
    - paste the bot token into SLACK.TOKEN
      - ex: `SLACK.TOKEN: "xoxb-5877962588738-5884133198226-8uBpNhurApo0kMZ0hMtHdmow"`
    - Ensure the channel name (*SLACK.CHANNEL*) matches with what you have in Slack
  - deployment.yaml
    - ensure the image points to the image location in ecr:
      ```
      - name: slack-connector
          image: >-
            748107796891.dkr.ecr.us-east-1.amazonaws.com/slack-connector:latest
          ports:
            - name: http
              containerPort: 8080
              protocol: TCP
      ```
  - service.yaml
    - ensure the *ports* section is consistent with deployment.yaml and that all names match
- update the configuration by running `kubectl apply -f k8s/<>.yaml` for each of the yaml files
- use the updated configuration by deleting the pod
  - run `kubectl get pod` and not the slack connector pod name
  - run `kubectl delete pod <slack-connector-pod-name>`
  - the pod will be brought back with the newly applied config 

#### Installing Event-Driven External Service Extensinons

- [Insall addon](https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=features-installing-add-feature-object-store) *5.5.4 Event-Driven External Service Invocation Extensions*

#### Create Event and Subscription

- From the ACCE Console, select and Object Store and navigate to *Events, Actions, Processes -> Event Actions* and create a new Event Action

![](https://zenhub.ibm.com/images/649c3ae08710884b790df62c/989a8942-173c-4e30-8302-945bb69955b4)

  - Give it a name of your choice and under *Event Action Type Selection*, select *Webhook*
  ![](https://zenhub.ibm.com/images/649c3ae08710884b790df62c/6c4386ee-d373-4ace-86a1-d57e9e8b021b)
  - Under *Webhook Configurations*:
    - set *External Event Receiver URL* to be `http://<image-name>:<port>/slack`
      - ex: `http://slack-connector:8080/slack`
    - set *External Event Receiver Registration Identifier* to be any name
  - Click *Finish* to Create the new Event
- Under *Data Design -> Classes -> Document*, click on *Actions -> New Class*
![](https://zenhub.ibm.com/images/649c3ae08710884b790df62c/facf4320-6dca-43fe-b0c9-f573641c52ac)
  - Enter any names you would like and proceed through the final screen (click *Finish*)
- Navigate to *Subscriptions* (also under *Events, Actions, Processes*) and create a New Subscription
![](https://zenhub.ibm.com/images/649c3ae08710884b790df62c/78d1b378-b779-47e8-a058-a784fb72ffac)
  - Under *Select Classes*, choose Document for the Class Type and your newly created class for the *Class*
  ![](https://zenhub.ibm.com/images/649c3ae08710884b790df62c/2ab11b5b-876c-43b2-a99f-bef028dfb45e)
  - For *Scope*, choose the *Applies to all objects of this class*
  - Under *Select the Triggers*, select *Creation Event* and *Update Event*
  - Under *Select an Event Action*, choose the Event Action you created in the previous step
  - Choose default options for the rest and click *Finish*

#### Test the App (Trigger Event Action)

- To Trigger the Event Action, Navigate to *Browse -> Root Folder* & create a new document
![](https://zenhub.ibm.com/images/649c3ae08710884b790df62c/688bd10d-6375-4d70-8066-a8558c111804)
- Under *Define New Document Objects*, be sure to select your newly created subclass for the *Class*
![](https://zenhub.ibm.com/images/649c3ae08710884b790df62c/e294827e-0b5f-4e77-93f0-962b9f2ebc43)
- Select any other options as you wish and click *Finish* to create the document
- Under the *Root Folder -> Content*, select your newly created document
- Click on *Properties* and modify one of them, for example, *Document Title*:
![](https://zenhub.ibm.com/images/649c3ae08710884b790df62c/15db8abe-e0f7-4996-b1a0-91e6b59a87c1)
- Open your Slack Channel. You should see the bot posting about the triggered Webhook:
![](https://zenhub.ibm.com/images/649c3ae08710884b790df62c/95235964-fdf0-498e-a3f2-409a7dbf3eb5)