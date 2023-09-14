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
- A Java Runtime Environment (JRE)
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

2. Configuring and Launching the Process Designer
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
    10. Enter credentials.
    11. Process Designer should open up!

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