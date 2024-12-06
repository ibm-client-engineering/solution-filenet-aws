"use strict";(self.webpackChunkwebsite=self.webpackChunkwebsite||[]).push([[1282],{7821:(e,i,n)=>{n.r(i),n.d(i,{assets:()=>a,contentTitle:()=>r,default:()=>h,frontMatter:()=>l,metadata:()=>c,toc:()=>o});var s=n(5893),t=n(1151);const l={id:"solution-filenet-workflow",sidebar_position:1,title:"Workflows"},r="FileNet Workflows",c={id:"Uses/solution-filenet-workflow",title:"Workflows",description:"Creating Workflows",source:"@site/docs/4-Uses/filenet_workflow.mdx",sourceDirName:"4-Uses",slug:"/Uses/solution-filenet-workflow",permalink:"/solution-filenet-aws/Uses/solution-filenet-workflow",draft:!1,unlisted:!1,editUrl:"https://github.com/ibm-client-engineering/solution-filenet-aws/tree/main/packages/create-docusaurus/templates/shared/docs/4-Uses/filenet_workflow.mdx",tags:[],version:"current",sidebarPosition:1,frontMatter:{id:"solution-filenet-workflow",sidebar_position:1,title:"Workflows"},sidebar:"tutorialSidebar",previous:{title:"Use Cases",permalink:"/solution-filenet-aws/Uses/Introduction"},next:{title:"Content Replication",permalink:"/solution-filenet-aws/Uses/solution-filenet-async-replication"}},a={},o=[{value:"Creating Workflows",id:"creating-workflows",level:2},{value:"Claim Filing &amp; Processing",id:"claim-filing--processing",level:3},{value:"Using Web Services",id:"using-web-services",level:3},{value:"Initiating Attachments",id:"initiating-attachments",level:3},{value:"Creating a Subclass (optional)",id:"creating-a-subclass-optional",level:4},{value:"Creating the Subscription",id:"creating-the-subscription",level:4},{value:"Workflow Init Attachment",id:"workflow-init-attachment",level:4}];function d(e){const i={a:"a",admonition:"admonition",em:"em",h1:"h1",h2:"h2",h3:"h3",h4:"h4",img:"img",li:"li",p:"p",ul:"ul",...(0,t.a)(),...e.components};return(0,s.jsxs)(s.Fragment,{children:[(0,s.jsx)(i.h1,{id:"filenet-workflows",children:"FileNet Workflows"}),"\n",(0,s.jsx)(i.h2,{id:"creating-workflows",children:"Creating Workflows"}),"\n",(0,s.jsx)(i.h3,{id:"claim-filing--processing",children:"Claim Filing & Processing"}),"\n",(0,s.jsx)(i.p,{children:"The following workflow was demonstrated and then subsequently recreated and tested in Traveler's environment. It is a sample workflow for processing a claim application. We expanded on this by triggering it via a document upload using a subscription created in the acce console, which we will also mark as an initiating attachment to automatically include it in the triggered workflow (see below)."}),"\n",(0,s.jsxs)(i.p,{children:["Workflow preview:\n",(0,s.jsx)(i.img,{src:"https://media.github.ibm.com/user/436100/files/4465abd7-143d-4385-8050-ee2a57a91bb7",alt:""})]}),"\n",(0,s.jsx)(i.p,{children:(0,s.jsx)(i.img,{src:"https://media.github.ibm.com/user/436100/files/0e65b54f-53bf-4f68-861b-18682b2608a7",alt:""})}),"\n",(0,s.jsx)(i.p,{children:"Workflow download:"}),"\n",(0,s.jsx)(i.p,{children:(0,s.jsx)(i.a,{href:"https://github.ibm.com/ibm-client-engineering/solution-filenet-aws/files/1242809/ClaimApplication.pep.zip",children:"ClaimApplication.pep.zip"})}),"\n",(0,s.jsx)(i.h3,{id:"using-web-services",children:"Using Web Services"}),"\n",(0,s.jsxs)(i.ul,{children:["\n",(0,s.jsxs)(i.li,{children:["In order to enable pasting wsdl partner links, navigate to ",(0,s.jsx)(i.em,{children:"View -> Configuration"}),":"]}),"\n"]}),"\n",(0,s.jsx)(i.p,{children:(0,s.jsx)(i.img,{src:"https://media.github.ibm.com/user/436100/files/db04cbaf-6cdd-439e-9310-38b6e2d594b6",alt:""})}),"\n",(0,s.jsxs)(i.ul,{children:["\n",(0,s.jsxs)(i.li,{children:["Right click on the connection point and click ",(0,s.jsx)(i.em,{children:"Properties..."}),":"]}),"\n"]}),"\n",(0,s.jsx)(i.p,{children:(0,s.jsx)(i.img,{src:"https://media.github.ibm.com/user/436100/files/bb20e3ed-ad22-4927-9bac-531eec0f55e1",alt:""})}),"\n",(0,s.jsxs)(i.ul,{children:["\n",(0,s.jsxs)(i.li,{children:["Under ",(0,s.jsx)(i.em,{children:"Web Services"}),", check ",(0,s.jsx)(i.em,{children:"Enable Process Designer to enter WSDL links without browsing for Web services"}),":"]}),"\n"]}),"\n",(0,s.jsx)(i.p,{children:(0,s.jsx)(i.img,{src:"https://media.github.ibm.com/user/436100/files/95c4e89d-fabc-41d0-85ec-a51fe141a1b5",alt:""})}),"\n",(0,s.jsxs)(i.ul,{children:["\n",(0,s.jsxs)(i.li,{children:["Now you can paste links in ",(0,s.jsx)(i.em,{children:"Workflow Properties"})," under ",(0,s.jsx)(i.em,{children:"Web Services"})," in the ",(0,s.jsx)(i.em,{children:"Partner Links"})," section:"]}),"\n"]}),"\n",(0,s.jsx)(i.p,{children:(0,s.jsx)(i.img,{src:"https://media.github.ibm.com/user/436100/files/29c67c90-2903-4f98-92cb-8a3d0ad3dd26",alt:""})}),"\n",(0,s.jsxs)(i.ul,{children:["\n",(0,s.jsxs)(i.li,{children:["Next, open up the Palette Menu and check ",(0,s.jsx)(i.em,{children:"Web Services Palette"}),":"]}),"\n"]}),"\n",(0,s.jsx)(i.p,{children:(0,s.jsx)(i.img,{src:"https://media.github.ibm.com/user/436100/files/7a174e99-650e-4a98-8860-f368ba4eb496",alt:""})}),"\n",(0,s.jsxs)(i.ul,{children:["\n",(0,s.jsxs)(i.li,{children:["Now you can drag in ",(0,s.jsx)(i.em,{children:"Invoke"})," and select the created ",(0,s.jsx)(i.em,{children:"Partner Link"})," as well as the desired ",(0,s.jsx)(i.em,{children:"Operation"}),":"]}),"\n"]}),"\n",(0,s.jsx)(i.p,{children:(0,s.jsx)(i.img,{src:"https://media.github.ibm.com/user/436100/files/719a4799-369b-4e6b-b09a-ec76c3e24a78",alt:""})}),"\n",(0,s.jsx)(i.admonition,{type:"note",children:(0,s.jsxs)(i.p,{children:["For web services that require SSL (ex. ",(0,s.jsx)(i.em,{children:"https://..."}),"), you must add a secret containing the certificate to the trusted_certificate_list in the CR."]})}),"\n",(0,s.jsx)(i.h3,{id:"initiating-attachments",children:"Initiating Attachments"}),"\n",(0,s.jsx)(i.p,{children:"Initiating attachments are attachments to Workflows that automatically get incorporated into them on upload, via a Subscription that triggers a workflow on Document Creation."}),"\n",(0,s.jsx)(i.h4,{id:"creating-a-subclass-optional",children:"Creating a Subclass (optional)"}),"\n",(0,s.jsx)(i.p,{children:"If desired, you can create a subclass of an exisitng one to use as a more specific type. This can provide finer granularity when, for example, triggering workflows."}),"\n",(0,s.jsxs)(i.ul,{children:["\n",(0,s.jsxs)(i.li,{children:["Within the acce console, navigte to your choice of object store, go to ",(0,s.jsx)(i.em,{children:"Classes"})," under ",(0,s.jsx)(i.em,{children:"Data Design"})," and double click on a class you would like to form a subclass for. Next, click on ",(0,s.jsx)(i.em,{children:"Actions"})," and ",(0,s.jsx)(i.em,{children:"New Class"}),":"]}),"\n"]}),"\n",(0,s.jsx)(i.p,{children:(0,s.jsx)(i.img,{src:"https://media.github.ibm.com/user/436100/files/6374e1f9-7a2e-46ec-9ca0-5250ffdcd8ea",alt:""})}),"\n",(0,s.jsxs)(i.ul,{children:["\n",(0,s.jsx)(i.li,{children:"Enter a name and description:"}),"\n"]}),"\n",(0,s.jsx)(i.p,{children:(0,s.jsx)(i.img,{src:"https://media.github.ibm.com/user/436100/files/6a4aad75-72ae-46c0-8d5c-04c90fb04096",alt:""})}),"\n",(0,s.jsxs)(i.ul,{children:["\n",(0,s.jsxs)(i.li,{children:["Click ",(0,s.jsx)(i.em,{children:"Finish"}),":"]}),"\n"]}),"\n",(0,s.jsx)(i.p,{children:(0,s.jsx)(i.img,{src:"https://media.github.ibm.com/user/436100/files/cc0ab9b9-380f-4701-91ec-387615d123f2",alt:""})}),"\n",(0,s.jsx)(i.h4,{id:"creating-the-subscription",children:"Creating the Subscription"}),"\n",(0,s.jsxs)(i.ul,{children:["\n",(0,s.jsxs)(i.li,{children:["In the acce console under your choice of object store, navigate to ",(0,s.jsx)(i.em,{children:"Events, Actions, Processes"})," and then to ",(0,s.jsx)(i.em,{children:"Subscriptions"}),":"]}),"\n"]}),"\n",(0,s.jsx)(i.p,{children:(0,s.jsx)(i.img,{src:"https://media.github.ibm.com/user/436100/files/a8d51fa1-55e2-4640-a5ef-68bbf59a4d1f",alt:""})}),"\n",(0,s.jsxs)(i.ul,{children:["\n",(0,s.jsxs)(i.li,{children:["Click ",(0,s.jsx)(i.em,{children:"New"})," and enter a name and description:"]}),"\n"]}),"\n",(0,s.jsx)(i.p,{children:(0,s.jsx)(i.img,{src:"https://media.github.ibm.com/user/436100/files/298624d4-42a4-4a91-a864-d9c9e89dc50f",alt:""})}),"\n",(0,s.jsxs)(i.ul,{children:["\n",(0,s.jsx)(i.li,{children:"Specify the class (and optionally subclass) you would like to subscribe to:"}),"\n"]}),"\n",(0,s.jsx)(i.p,{children:(0,s.jsx)(i.img,{src:"https://media.github.ibm.com/user/436100/files/714ebd0f-246e-4d54-a576-56e4bcbd45c0",alt:""})}),"\n",(0,s.jsxs)(i.ul,{children:["\n",(0,s.jsxs)(i.li,{children:["Check ",(0,s.jsx)(i.em,{children:"Create a workflow subscription"})," to allow this subscription to trigger a workflow:"]}),"\n"]}),"\n",(0,s.jsx)(i.p,{children:(0,s.jsx)(i.img,{src:"https://media.github.ibm.com/user/436100/files/e51cc792-63ef-489e-9eba-ebcdc5f723a0",alt:""})}),"\n",(0,s.jsxs)(i.ul,{children:["\n",(0,s.jsxs)(i.li,{children:["Select the events you would like to trigger the workflow. ",(0,s.jsx)(i.em,{children:"Creation"})," of a document signifies a document upload:"]}),"\n"]}),"\n",(0,s.jsx)(i.p,{children:(0,s.jsx)(i.img,{src:"https://media.github.ibm.com/user/436100/files/e3158b7a-0eeb-43a4-b50a-76f0a48d1883",alt:""})}),"\n",(0,s.jsxs)(i.ul,{children:["\n",(0,s.jsx)(i.li,{children:"Specify which Workflow you would like this subscription to trigger:"}),"\n"]}),"\n",(0,s.jsx)(i.p,{children:(0,s.jsx)(i.img,{src:"https://media.github.ibm.com/user/436100/files/e1b73b54-2bcf-48b8-b992-94dc940f5907",alt:""})}),"\n",(0,s.jsxs)(i.ul,{children:["\n",(0,s.jsxs)(i.li,{children:["Optionally map properties from the uploaded document (",(0,s.jsx)(i.em,{children:"Property name"}),") to the Workflow (",(0,s.jsx)(i.em,{children:"Data field name"}),"):"]}),"\n"]}),"\n",(0,s.jsx)(i.p,{children:(0,s.jsx)(i.img,{src:"https://media.github.ibm.com/user/436100/files/1c47382e-f8b2-4f32-b001-03af611448b2",alt:""})}),"\n",(0,s.jsxs)(i.ul,{children:["\n",(0,s.jsx)(i.li,{children:"Ensure the subscription is enabled and if you would like, include subclasses:"}),"\n"]}),"\n",(0,s.jsx)(i.p,{children:(0,s.jsx)(i.img,{src:"https://media.github.ibm.com/user/436100/files/72fdeb48-fbf6-40d8-935f-1c4fdae3ae7c",alt:""})}),"\n",(0,s.jsxs)(i.ul,{children:["\n",(0,s.jsxs)(i.li,{children:["Review the details and click ",(0,s.jsx)(i.em,{children:"Finish"}),":"]}),"\n"]}),"\n",(0,s.jsxs)(i.p,{children:[(0,s.jsx)(i.img,{src:"https://media.github.ibm.com/user/436100/files/73330507-6e63-4524-a224-45e5cfb928ec",alt:""}),"\n",(0,s.jsx)(i.img,{src:"https://media.github.ibm.com/user/436100/files/bb803613-3dd6-4134-8272-c40790343a2d",alt:""})]}),"\n",(0,s.jsx)(i.h4,{id:"workflow-init-attachment",children:"Workflow Init Attachment"}),"\n",(0,s.jsxs)(i.ul,{children:["\n",(0,s.jsxs)(i.li,{children:["Under ",(0,s.jsx)(i.em,{children:"Workflow Properties"})," in the ",(0,s.jsx)(i.em,{children:"Attachments"})," tab, create an attachment by double clicking under the ",(0,s.jsx)(i.em,{children:"Name"})," field, typing a name and pressing Enter:"]}),"\n"]}),"\n",(0,s.jsx)(i.p,{children:(0,s.jsx)(i.img,{src:"https://media.github.ibm.com/user/436100/files/75ca2f4b-f3f5-4aec-ab24-f5c05553aed1",alt:""})}),"\n",(0,s.jsxs)(i.ul,{children:["\n",(0,s.jsxs)(i.li,{children:["On the right sidebar, mark this as the ",(0,s.jsx)(i.em,{children:"Initiating attachment"})," by clicking the following icon, which should then appear left of the attachment name:"]}),"\n"]}),"\n",(0,s.jsxs)(i.p,{children:[(0,s.jsx)(i.img,{src:"https://media.github.ibm.com/user/436100/files/c9a35503-02b8-44c1-bec0-7da6611ba876",alt:""}),"\n\u2003\u2003\u2003\u2003\u2003\u2003\u2003\u2003\u2003\u2003\u2003\n",(0,s.jsx)(i.img,{src:"https://media.github.ibm.com/user/436100/files/33d603f9-6313-4a6f-9036-10d4ad9e82e2",alt:""})]}),"\n",(0,s.jsxs)(i.ul,{children:["\n",(0,s.jsx)(i.li,{children:"From the palette menu, drag in a component node:"}),"\n"]}),"\n",(0,s.jsx)(i.p,{children:(0,s.jsx)(i.img,{src:"https://media.github.ibm.com/user/436100/files/83dabcd3-90e6-4dbb-b881-cbce049fb45f",alt:""})}),"\n",(0,s.jsxs)(i.ul,{children:["\n",(0,s.jsx)(i.li,{children:"Configure this component by selecting an operation to extract information from the uploaded attachment, such as its given title, for example, which corresponds to symbolicPropName:"}),"\n"]}),"\n",(0,s.jsx)(i.p,{children:(0,s.jsx)(i.img,{src:"https://media.github.ibm.com/user/436100/files/320f420c-2c6d-454a-8203-4a55799f3edf",alt:""})}),"\n",(0,s.jsx)(i.p,{children:"This then populates the return value, which can be used elsewhere in the Workflow as desired."})]})}function h(e={}){const{wrapper:i}={...(0,t.a)(),...e.components};return i?(0,s.jsx)(i,{...e,children:(0,s.jsx)(d,{...e})}):d(e)}},1151:(e,i,n)=>{n.d(i,{Z:()=>c,a:()=>r});var s=n(7294);const t={},l=s.createContext(t);function r(e){const i=s.useContext(l);return s.useMemo((function(){return"function"==typeof e?e(i):{...i,...e}}),[i,e])}function c(e){let i;return i=e.disableParentContext?"function"==typeof e.components?e.components(t):e.components||t:r(e.components),s.createElement(l.Provider,{value:i},e.children)}}}]);