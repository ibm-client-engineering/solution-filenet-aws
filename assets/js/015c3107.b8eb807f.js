"use strict";(self.webpackChunkwebsite=self.webpackChunkwebsite||[]).push([[6478],{3905:(e,t,a)=>{a.d(t,{Zo:()=>p,kt:()=>m});var n=a(7294);function i(e,t,a){return t in e?Object.defineProperty(e,t,{value:a,enumerable:!0,configurable:!0,writable:!0}):e[t]=a,e}function o(e,t){var a=Object.keys(e);if(Object.getOwnPropertySymbols){var n=Object.getOwnPropertySymbols(e);t&&(n=n.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),a.push.apply(a,n)}return a}function r(e){for(var t=1;t<arguments.length;t++){var a=null!=arguments[t]?arguments[t]:{};t%2?o(Object(a),!0).forEach((function(t){i(e,t,a[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(a)):o(Object(a)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(a,t))}))}return e}function l(e,t){if(null==e)return{};var a,n,i=function(e,t){if(null==e)return{};var a,n,i={},o=Object.keys(e);for(n=0;n<o.length;n++)a=o[n],t.indexOf(a)>=0||(i[a]=e[a]);return i}(e,t);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);for(n=0;n<o.length;n++)a=o[n],t.indexOf(a)>=0||Object.prototype.propertyIsEnumerable.call(e,a)&&(i[a]=e[a])}return i}var c=n.createContext({}),s=function(e){var t=n.useContext(c),a=t;return e&&(a="function"==typeof e?e(t):r(r({},t),e)),a},p=function(e){var t=s(e.components);return n.createElement(c.Provider,{value:t},e.children)},d="mdxType",u={inlineCode:"code",wrapper:function(e){var t=e.children;return n.createElement(n.Fragment,{},t)}},h=n.forwardRef((function(e,t){var a=e.components,i=e.mdxType,o=e.originalType,c=e.parentName,p=l(e,["components","mdxType","originalType","parentName"]),d=s(a),h=i,m=d["".concat(c,".").concat(h)]||d[h]||u[h]||o;return a?n.createElement(m,r(r({ref:t},p),{},{components:a})):n.createElement(m,r({ref:t},p))}));function m(e,t){var a=arguments,i=t&&t.mdxType;if("string"==typeof e||i){var o=a.length,r=new Array(o);r[0]=h;var l={};for(var c in t)hasOwnProperty.call(t,c)&&(l[c]=t[c]);l.originalType=e,l[d]="string"==typeof e?e:i,r[1]=l;for(var s=2;s<o;s++)r[s]=a[s];return n.createElement.apply(null,r)}return n.createElement.apply(null,a)}h.displayName="MDXCreateElement"},6712:(e,t,a)=>{a.r(t),a.d(t,{assets:()=>c,contentTitle:()=>r,default:()=>u,frontMatter:()=>o,metadata:()=>l,toc:()=>s});var n=a(7462),i=(a(7294),a(3905));const o={id:"solution-integrate",sidebar_position:3,title:"Integrate"},r="Integrate",l={unversionedId:"Create/solution-integrate",id:"Create/solution-integrate",title:"Integrate",description:"Standalone Process Designer Setup",source:"@site/docs/3-Create/Integrate.md",sourceDirName:"3-Create",slug:"/Create/solution-integrate",permalink:"/solution-filenet-aws/Create/solution-integrate",draft:!1,editUrl:"https://github.com/ibm-client-engineering/solution-filenet-aws/tree/main/packages/create-docusaurus/templates/shared/docs/3-Create/Integrate.md",tags:[],version:"current",sidebarPosition:3,frontMatter:{id:"solution-integrate",sidebar_position:3,title:"Integrate"},sidebar:"tutorialSidebar",previous:{title:"Validate",permalink:"/solution-filenet-aws/Create/solution-validate"},next:{title:"Automate",permalink:"/solution-filenet-aws/Create/solution-automate"}},c={},s=[{value:"Standalone Process Designer Setup",id:"standalone-process-designer-setup",level:2},{value:"Version info",id:"version-info",level:3},{value:"Prerequisites",id:"prerequisites",level:3},{value:"Setup Steps:",id:"setup-steps",level:3},{value:"Synchronous/Asynchronous Replication in FileNet",id:"synchronousasynchronous-replication-in-filenet",level:2},{value:"Creating an Advanced Storage Device",id:"creating-an-advanced-storage-device",level:3},{value:"Creating an Advanced Storage Area",id:"creating-an-advanced-storage-area",level:3},{value:"Configuring FileNet Replication",id:"configuring-filenet-replication",level:3},{value:"Asynchronous replication",id:"asynchronous-replication",level:3},{value:"Testing Synchronous/Asynchronous Replication in FileNet",id:"testing-synchronousasynchronous-replication-in-filenet",level:3}],p={toc:s},d="wrapper";function u(e){let{components:t,...a}=e;return(0,i.kt)(d,(0,n.Z)({},p,a,{components:t,mdxType:"MDXLayout"}),(0,i.kt)("h1",{id:"integrate"},"Integrate"),(0,i.kt)("h2",{id:"standalone-process-designer-setup"},"Standalone Process Designer Setup"),(0,i.kt)("h3",{id:"version-info"},"Version info"),(0,i.kt)("ul",null,(0,i.kt)("li",{parentName:"ul"},"IBM Content Platform Engine - 5.5.10.0"),(0,i.kt)("li",{parentName:"ul"},"IBM Content Navigator 3.0.13")),(0,i.kt)("h3",{id:"prerequisites"},"Prerequisites"),(0,i.kt)("ul",null,(0,i.kt)("li",{parentName:"ul"},"A Java Runtime Environment (JRE)"),(0,i.kt)("li",{parentName:"ul"},"Install the Filenet Content Manager CPE tools package from IBM Passport Advantage using the part number ",(0,i.kt)("inlineCode",{parentName:"li"},"M0CTDML"))),(0,i.kt)("h3",{id:"setup-steps"},"Setup Steps:"),(0,i.kt)("ol",null,(0,i.kt)("li",{parentName:"ol"},(0,i.kt)("p",{parentName:"li"},"Creating a Workflow System and Connection Point within Filenet"),(0,i.kt)("ol",{parentName:"li"},(0,i.kt)("li",{parentName:"ol"},"Open up and log into the acce console."),(0,i.kt)("li",{parentName:"ol"},"Open the Object Store in which you want to store Workflow data."),(0,i.kt)("li",{parentName:"ol"},"Click on ",(0,i.kt)("em",{parentName:"li"},"Administrative->Workflow")," System."),(0,i.kt)("li",{parentName:"ol"},"Click New."),(0,i.kt)("li",{parentName:"ol"},"Under ",(0,i.kt)("em",{parentName:"li"},"Table Spaces -> Data"),", enter the tablespace where you want workflow files to be stored."),(0,i.kt)("li",{parentName:"ol"},"Under ",(0,i.kt)("em",{parentName:"li"},"Workflow System Security Groups -> Administration Group"),", enter the admin group you want to assign to the Workflow System. These two can be found in your filenet configuration (you can log into the database and see the tablespaces if needed)."),(0,i.kt)("li",{parentName:"ol"},"Continue through the steps adding Connection Point and Isolated Region names and enter the ",(0,i.kt)("em",{parentName:"li"},"Isolated Region Number")," (1 if it\u2019s your first in this object store, and so on)."),(0,i.kt)("li",{parentName:"ol"},"If you wish, you can ",(0,i.kt)("em",{parentName:"li"},"Specify Isolated Region Table Space (Optional)"),"."),(0,i.kt)("li",{parentName:"ol"},"Review all the details and click ",(0,i.kt)("em",{parentName:"li"},"Finish"),"."),(0,i.kt)("li",{parentName:"ol"},"Navigate to ",(0,i.kt)("em",{parentName:"li"},"Workflow System->Connection Points")," to confirm that it was successfully created."))),(0,i.kt)("li",{parentName:"ol"},(0,i.kt)("p",{parentName:"li"},"Configuring and Launching the Process Designer"),(0,i.kt)("ol",{parentName:"li"},(0,i.kt)("li",{parentName:"ol"},"Unzip the Process Designer zip file and all zip files within it for your platform."),(0,i.kt)("li",{parentName:"ol"},"Navigate to: ",(0,i.kt)("inlineCode",{parentName:"li"},"<unzipped_folder>/cpetools-<platform>/peclient/")),(0,i.kt)("li",{parentName:"ol"},"Open this folder in any text editor or IDE (ex. code .)."),(0,i.kt)("li",{parentName:"ol"},"Open:")),(0,i.kt)("ul",{parentName:"li"},(0,i.kt)("li",{parentName:"ul"},(0,i.kt)("inlineCode",{parentName:"li"},"shell/cpetoolenv.sh")," (Linux/Mac)"),(0,i.kt)("li",{parentName:"ul"},(0,i.kt)("inlineCode",{parentName:"li"},"batch/cpetoolenv.bat")," (Windows)")),(0,i.kt)("ol",{parentName:"li",start:4},(0,i.kt)("li",{parentName:"ol"},"Set the ",(0,i.kt)("inlineCode",{parentName:"li"},"PE_CLIENT_INSTALL_DIR")," to the full path of the ",(0,i.kt)("inlineCode",{parentName:"li"},"cpe_tools-<platform>")," directory, i.e., ",(0,i.kt)("inlineCode",{parentName:"li"},"/Users/\u2026/<unzipped_folder>/cpetools-linux"),", beware of any spaces in the folder path."),(0,i.kt)("li",{parentName:"ol"},"Open ",(0,i.kt)("inlineCode",{parentName:"li"},"config/WcmApiConfig.properties"),"."),(0,i.kt)("li",{parentName:"ol"},"Set the ",(0,i.kt)("inlineCode",{parentName:"li"},"RemoteServerUrl"),":")),(0,i.kt)("ul",{parentName:"li"},(0,i.kt)("li",{parentName:"ul"},"If you access the acce console at ",(0,i.kt)("inlineCode",{parentName:"li"},"<host_link>/acce/"),", then confirm you can access the ping page at ",(0,i.kt)("inlineCode",{parentName:"li"},"<host_link>/peengine/IOR/ping"),"."),(0,i.kt)("li",{parentName:"ul"},"If you can get to this page, then your ",(0,i.kt)("inlineCode",{parentName:"li"},"RemoteServerUrl")," is likely to be ",(0,i.kt)("inlineCode",{parentName:"li"},"<host_link>/wsi/FNCEWS40TOM"),".")),(0,i.kt)("ol",{parentName:"li",start:7},(0,i.kt)("li",{parentName:"ol"},"Open a command line utility (i.e., Terminal ","[Mac]",", cmd ","[Windows]",")."),(0,i.kt)("li",{parentName:"ol"},"Navigate (cd) to:")),(0,i.kt)("ul",{parentName:"li"},(0,i.kt)("li",{parentName:"ul"},(0,i.kt)("inlineCode",{parentName:"li"},"<unzipped_folder>/cpetools-linux/peclient/shell")," (Linux/Mac)"),(0,i.kt)("li",{parentName:"ul"},(0,i.kt)("inlineCode",{parentName:"li"},"<unzipped_folder>/cpetools-win/peclient/batch")," (Windows)")),(0,i.kt)("ol",{parentName:"li",start:9},(0,i.kt)("li",{parentName:"ol"},"Run:")),(0,i.kt)("ul",{parentName:"li"},(0,i.kt)("li",{parentName:"ul"},(0,i.kt)("inlineCode",{parentName:"li"},"sh ./pedesigner.sh <connection_point>")," (Linux/Mac)"),(0,i.kt)("li",{parentName:"ul"},(0,i.kt)("inlineCode",{parentName:"li"},"pedesigner.bat <connection_point>")," (Windows)")),(0,i.kt)("ol",{parentName:"li",start:10},(0,i.kt)("li",{parentName:"ol"},"Enter credentials."),(0,i.kt)("li",{parentName:"ol"},"Process Designer should open up!")))),(0,i.kt)("h2",{id:"synchronousasynchronous-replication-in-filenet"},"Synchronous/Asynchronous Replication in FileNet"),(0,i.kt)("h3",{id:"creating-an-advanced-storage-device"},"Creating an Advanced Storage Device"),(0,i.kt)("p",null,"Advanced Storage Devices are attached to Advanced Storage Areas and will be the devices used for replication. To create an Advanced Storage Device, log into the Administrative Console for Content Platform Engine and select the Object Store you want to use."),(0,i.kt)("p",null,(0,i.kt)("img",{parentName:"p",src:"https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/6daf8c2c-2690-475b-9d7b-ec02da646a6d",alt:"FileNet Replication Object Store Select.png"})),(0,i.kt)("p",null,"Once inside the Object Store, navigate to Administrative -> Storage -> Advanced Storage -> Advanced Storage Devices. Once inside the Advanced Storage Devices folder, you should see several different devices such as Azure Blog, File System, OpenStack, and Simple Storage Service (S3)."),(0,i.kt)("p",null,(0,i.kt)("img",{parentName:"p",src:"https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/e8bb5ffd-55c1-49cc-9e1e-c9d52ec38363",alt:"FileNet Replication Advanced Storage Area Devices Location.png"})),(0,i.kt)("p",null,"Before creating another Advanced Storage Device, there should already be a File System Storage device. This device was automatically configured during the initial FileNet installation. Let\u2019s go to the File System Storage Device folder and verify."),(0,i.kt)("p",null,(0,i.kt)("img",{parentName:"p",src:"https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/a17a8d33-78d3-49c8-99c9-b99a7038da63",alt:"FileNet Replication Adv Storage File system Storage Device.png"})),(0,i.kt)("p",null,'This storage is an AWS Elastic File Share (EFS) storage Persistent Volume (PV), and it is being attached to the pod FileNet is running on. In the image above we can see where this PV is mounted under "Root Direct Path". Also, because this device is using EFS, we get all the resilience that comes standard with AWS EFS. We will be using this device later in an Advanced Storage Area.'),(0,i.kt)("p",null,'Now let\u2019s create another Advanced Storage Device. We will be setting up an S3 Bucket as another Advanced Storage Device. To do this, in the same Advanced Storage Devices folder you should see another folder named Simple Storage Service (S3) Devices. Once there click on the "New" button to create a new S3 Advanced Storage Device.'),(0,i.kt)("p",null,(0,i.kt)("img",{parentName:"p",src:"https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/d1edfc83-5ce6-4994-97c1-c06a0fb49b4f",alt:"FileNet Replication Adv Storage S3 Location.png"})),(0,i.kt)("p",null,'Next, we will be prompted to enter a display name for our S3 device in FileNet. This does not have to be the same name as your actual S3 bucket. This will be the device name within FileNet. Fill this out and select "Next".'),(0,i.kt)("p",null,(0,i.kt)("img",{parentName:"p",src:"https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/a39b88a0-910a-4af5-a060-5b011e190a99",alt:"FileNet Replication Adv Storage S3 Name.png"})),(0,i.kt)("p",null,'On the next page, enter the details for your user Key ID, Secret Access Key, and the S3 bucket details. Then click "next".'),(0,i.kt)("p",null,(0,i.kt)("img",{parentName:"p",src:"https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/bad61b23-e7fe-4e87-81a9-6236b5d7e21f",alt:"FileNet Replication Adv Storage S3 setup.png"})),(0,i.kt)("p",null,'The following page will display all your selected options and entered values for the S3 configuration. Validate the information and if everything looks correct select "Finish". FileNet will then try to connect to that S3 bucket. When it successfully connects you should see a confirmation message.'),(0,i.kt)("p",null,(0,i.kt)("img",{parentName:"p",src:"https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/ef072216-3d76-4a5c-9343-c411f7eb12b1",alt:"FileNet Replication Adv Storage s3 Confirmation.png"})),(0,i.kt)("h3",{id:"creating-an-advanced-storage-area"},"Creating an Advanced Storage Area"),(0,i.kt)("p",null,"Once we have connected Advanced Storage Devices to FileNet, we can create an Advanced Storage Area. Advanced Storage Areas handle how data is managed, replicated, and configured on Advanced Storage Devices. So, we associate one or more Advanced Storage Devices to an Advanced Storage Area and the Advanced Storage Area will manage those Advanced Storage Devices such as S3, EFS, etc."),(0,i.kt)("p",null,'Now let\u2019s create an Advanced Storage Area. Within the same Object Store you created your Advanced Storage Devices, navigate to Administrative -> Storage -> Advanced Storage -> Advanced Storage Areas. Once there select "New".'),(0,i.kt)("p",null,(0,i.kt)("img",{parentName:"p",src:"https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/52a9f635-20a4-48a1-a95e-55f4c8028a4f",alt:"FileNet Replication Adv Storage Area Location.png"})),(0,i.kt)("p",null,'The next screen will prompt us for a name for the Advanced Storage Area. Enter any name that you like and then select "next".'),(0,i.kt)("p",null,(0,i.kt)("img",{parentName:"p",src:"https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/13f54367-03a5-49c3-a459-b660a1300213",alt:"FileNet Replication Adv Storage Area Name.png"})),(0,i.kt)("p",null,'The next screen will ask some general questions about the Advanced Storage Area configuration. You should see an "Encryption Method" option. Set "Encryption Method" to disabled and leave the other settings default. Then select "next".'),(0,i.kt)("p",null,(0,i.kt)("img",{parentName:"p",src:"https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/f8865d1b-4214-4f62-a4a5-1d3bb2246a83",alt:"FileNet Replication Adv Storage Area Configuration.png"})),(0,i.kt)("p",null,'The next page will ask you what Advanced Storage Devices you want to add to the Advanced Storage Area. Advanced Storage Area refers to Advanced Storage Devices as "Replicas". In the section "Creating an Advanced Storage Device". There were two Advanced Storage Devices. One was an EFS File System Storage device that came preinstalled with the FileNet installation and another S3 Advanced Storage Device we added. Both should appear in the area named "Available Storage Replication Devices". Select the boxes next to those devices and a checkmark should appear.'),(0,i.kt)("p",null,'Right above that option you should see "Required Synchronous Devices". This is where we set how many synchronous devices are required for a successful document upload. FileNet must write synchronously to this specific number of devices for the upload to complete and be successful. For now, we can put the value "1" here.'),(0,i.kt)("p",null,(0,i.kt)("img",{parentName:"p",src:"https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/1e8ccc0d-7813-4620-bd00-551a23748c22",alt:"FileNet Replication Adv Storage Area Devices.png"})),(0,i.kt)("p",null,'Keep selecting next and leaving all options default until you get to the Summary page. You will get a warning about not setting a storage policy. We can always set that later. Click "OK" on the warning. The Summary page displays all your configuration options. If everything looks correct click "Finish" at the top.'),(0,i.kt)("p",null,(0,i.kt)("img",{parentName:"p",src:"https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/7f6bb3fc-688d-4a4a-a58a-aebe81b1c17b",alt:"FileNet Replication Adv Storage Area Confirmation.png"})),(0,i.kt)("p",null,"You should now see the newly created Advanced Storage Area in the list."),(0,i.kt)("p",null,(0,i.kt)("img",{parentName:"p",src:"https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/92c815f7-c5e6-487b-83b3-3c974b55cc46",alt:"FileNet Replication Adv Storage Area List.png"})),(0,i.kt)("h3",{id:"configuring-filenet-replication"},"Configuring FileNet Replication"),(0,i.kt)("p",null,"Once we have created an Advanced Storage Area and have attached Advanced Storage Devices, we can now configure the replication within that Advanced Storage Area. To configure the replication, navigate to Administrative -> Storage -> Advanced Storage -> Advanced Storage Areas. Here we should see the Advanced Storage Area we created in the previous section. Click on the name of the Advanced Storage Area."),(0,i.kt)("p",null,(0,i.kt)("img",{parentName:"p",src:"https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/7421f1ea-5daf-474e-9283-257e5a47f5b4",alt:"FileNet Replication Adv Storage Area.png"})),(0,i.kt)("p",null,'Once you clicked on the Advanced Storage Area, the page should now display the configuration settings for that Advanced Storage Area. Click on the "Devices" Tab.'),(0,i.kt)("p",null,(0,i.kt)("img",{parentName:"p",src:"https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/fd71e0dc-6288-407c-865f-671a78ffed18",alt:"FileNet Replication Adv Storage Area Device Settings.png"})),(0,i.kt)("p",null,'There will be several settings here but let\u2019s start with "Maximum synchronous devices" and "Required synchronous devices". These settings act as an upper and lower limit on the number of synchronous devices written to when a document is uploaded. The "Maximum synchronous devices" tells FileNet that, when possible, write to this specified number of devices. "Required synchronous devices" tells FileNet that it must write to this specified number of devices for the upload to be successful. You can see how this creates a type of range for the synchronous replication.'),(0,i.kt)("p",null,(0,i.kt)("img",{parentName:"p",src:"https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/7d8d73a2-d018-4916-8c1e-4fabddae3730",alt:"FileNet Replication Adv Storage Area Min Max synch devices.png"})),(0,i.kt)("p",null,'Now let\u2019s configure the replication for the individual devices in the Advanced Storage Area. In the same page you see a box named "Device Connections". In this box you should see the Advanced Storage Devices connected to this Advanced Storage Area. We should see the devices that we added in the previous sections. To the right of each of these devices, we should see an option called "Default Synch Type".'),(0,i.kt)("p",null,(0,i.kt)("img",{parentName:"p",src:"https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/2e3f674f-f502-4be2-ba4c-3e13bbeb4554",alt:"FileNet Replication Adv Storage Area Settings Default Synch Type.png"})),(0,i.kt)("p",null,"This option controls the device replication priority and type. There are three Default Synch Types:"),(0,i.kt)("ul",null,(0,i.kt)("li",{parentName:"ul"},"Primary Synchronous - They are the primary, priority devices that FileNet will try to write synchronous operations to."),(0,i.kt)("li",{parentName:"ul"},'Secondary Synchronous - If FileNet has exhausted all devices marked "Primary Synchronous", FileNet will then start using devices marked as "Secondary Synchronous" for synchronous write operations.'),(0,i.kt)("li",{parentName:"ul"},"Asynchronous - Devices with this type are always written to asynchronously and are not part of synchronous write operations.")),(0,i.kt)("p",null,"This logic is further demonstrated in the following diagram:"),(0,i.kt)("p",null,(0,i.kt)("img",{parentName:"p",src:"https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/722f3cad-6dc4-4e22-b6cf-fcfbdb828a37",alt:"FileNet Replication Flow Diagram.png"})),(0,i.kt)("p",null,"**",(0,i.kt)("em",{parentName:"p"},"NOTE: This diagram is meant to illustrate Default Synch Type priority and logic. This diagram does not take into account settings like maximum number of synchronous devices, how FileNet handles extra storage devices, or other FileNet factors and settings.")),(0,i.kt)("h3",{id:"asynchronous-replication"},"Asynchronous replication"),(0,i.kt)("p",null,(0,i.kt)("em",{parentName:"p"},"Synchronous replication is discussed in the previous section ",(0,i.kt)("a",{parentName:"em",href:"#configuring-filenet-replication"},"Configuring FileNet Replication"),".")),(0,i.kt)("p",null,"Content can also be written to replicas asynchronously with the content replication request sweep. Asynchronous replication is used under the following conditions:"),(0,i.kt)("ul",null,(0,i.kt)("li",{parentName:"ul"},"A storage device connection for a replica is explicitly configured for asynchronous replication. "),(0,i.kt)("li",{parentName:"ul"},"If the maximum number of synchronous replicas has already been reached, but there are other primary or secondary designated replicas available, then, for performance purposes, the advanced storage area writes asynchronously to the remaining replicas."),(0,i.kt)("li",{parentName:"ul"},"A synchronous write attempt to a replica fails. For example, if a primary replica fails, but the required number of primary replicas is satisfied, the advanced storage area places the write request to the failed replica in the replication sweep queue. The replication queue sweep writes the content after the failed replica is restored.")),(0,i.kt)("p",null,"We mentioned that content is written asynchronously with content replication request sweeps. Sweeps are types of background jobs that run within FileNet. Once an object meets a configured criteria, the sweep performs an action on the object. There are several types of Sweeps in FileNet, and you can even create custom Sweeps. But for replication, this task is handled by content replication request sweeps. Content replication request sweeps are a type of Queue Sweep. Once FileNet has determined an asynchronous replication task, content replication request sweeps will try to write asynchronously to the replicas that meet the conditions that we previously discussed. Depending on factors within FileNet, content replication request sweeps may try to carry out that asynchronous write immediately or it might put it in a queue to be processed later. There are many factors that might cause the asynchronous job to be put in a queue, such as capacity, device availability, scheduling and so on."),(0,i.kt)("p",null,"Now that we have discussed the role of Sweeps in FileNet and how asynchronous write operations are handled by content replication request sweeps, let\u2019s go into the Admin Console and view content replication request sweeps. Withing the Admin Console, select the Object Store that you used to create you Advanced Storage Area and Devices. Once inside that Object Store, navigate to Sweep Management -> Queue Sweeps -> Content Replication Sweep."),(0,i.kt)("p",null,(0,i.kt)("img",{parentName:"p",src:"https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/7986557f-b186-42f4-952a-faf5f05c65d4",alt:"FileNet Replication Content Replication Sweep Location.png"})),(0,i.kt)("p",null,"Once here, we can configure how the Content Replication Sweep runs. For instance, we can set a schedule for the Content Replication Sweep. If we only want asynchronous write operations to occur at certain times of the day, we can set that here."),(0,i.kt)("p",null,(0,i.kt)("img",{parentName:"p",src:"https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/4f4232c7-b71d-4141-b506-77b6daee02d7",alt:"FileNet Replication Content Replication Sweep Scheduling.png"})),(0,i.kt)("p",null,'Asynchronous jobs waiting to be executed by the Content Replication Sweep remain in the "Queue Entries" within the Content Replication Sweep. This queue shows upcoming asynchronous write operations along with other information such as status, failure count, etc. This information can be found by selecting the Queue Entries" tab within the Content Replication Sweep.'),(0,i.kt)("p",null,(0,i.kt)("img",{parentName:"p",src:"https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/3d63eac2-5d83-4512-a782-a6ae80a6d070",alt:"FileNet Replication Content Replication Sweep Queue Entries.png"})),(0,i.kt)("h3",{id:"testing-synchronousasynchronous-replication-in-filenet"},"Testing Synchronous/Asynchronous Replication in FileNet"),(0,i.kt)("p",null,'To test our synchronous/asynchronous configurations we can upload a document to FileNet. Withing the Admin Console, select the Object Store that you used to create you Advanced Storage Area and Devices. Then navigate to Browse. Within browse there will be a folder called "Root Folder". We can upload a document here or create another folder and upload it there. For our testing, lets upload to the Root Folder. Click on the Root Folder to enter. Once inside the Root Folder Select the "Actions" dropdown and select "New Document".'),(0,i.kt)("p",null,(0,i.kt)("img",{parentName:"p",src:"https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/f6380fcb-4bba-4f24-98c6-de614b44d6ae",alt:"FileNet Replication Content Replication Test Location.png"})),(0,i.kt)("p",null,'Give a name to the document and select "next".'),(0,i.kt)("p",null,(0,i.kt)("img",{parentName:"p",src:"https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/24500f87-83c3-469f-a0ac-3565603a8aec",alt:"FileNet Replication Test Name.png"}),"!"),(0,i.kt)("p",null,'We will now need to add content to the document. To add a file, click "Add" in the "Content Elements". A pop-up window should appear named "Add Content Element". Add any file here and then select "Add Content" button on the bottom. The file we selected should appear in the Content Elements. Then select "Next".'),(0,i.kt)("p",null,(0,i.kt)("img",{parentName:"p",src:"https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/db4bb1f6-677c-4497-8260-6909324a17cc",alt:"FileNet Replication Test Add Content.png"}),"\n",(0,i.kt)("img",{parentName:"p",src:"https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/aad8b52f-5238-49d3-a133-f862374d7d4c",alt:"FileNet Replication Test Add Content page.png"})),(0,i.kt)("p",null,'Keep selecting next and leaving all settings default until you get to the "Advanced Features" page. Here we need to select the Advanced Storage Area we created in the previous section. Once we have selected the storage area, select "next".'),(0,i.kt)("p",null,(0,i.kt)("img",{parentName:"p",src:"https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/75f27860-e33a-4c5b-9f25-12ccef025b21",alt:"FileNEt Replication Test Storage Area Selection.png"})),(0,i.kt)("p",null,'The next page will be the summary page. The Summary page displays all your configuration options. If everything looks correct click "Finish" at the top.'),(0,i.kt)("p",null,"You can now check your storage devices to verify the document was uploaded. Asynchronous writes may have the appearance of synchronous writes at times. This is because there is nothing like a schedule, capacity, or other limiting configurations that would cause the asynchronous write operation to be put into the queue. So, the content replication request sweep immediately executes the asynchronous write operation."))}u.isMDXComponent=!0}}]);