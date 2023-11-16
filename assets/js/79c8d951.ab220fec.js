"use strict";(self.webpackChunkwebsite=self.webpackChunkwebsite||[]).push([[1078],{5207:(e,t,n)=>{n.r(t),n.d(t,{assets:()=>l,contentTitle:()=>i,default:()=>h,frontMatter:()=>a,metadata:()=>r,toc:()=>c});var s=n(5893),o=n(1151);const a={id:"solution-lessons",sidebar_position:1,title:"Lessons Learned"},i=void 0,r={id:"Transition/solution-lessons",title:"Lessons Learned",description:"Throughout our journey on this project, the team encountered many obstacles. This section will outline any errors, blockers, and setbacks the team faced. We will discuss how these blockers were identified and resolved.",source:"@site/docs/4-Transition/lessons.md",sourceDirName:"4-Transition",slug:"/Transition/solution-lessons",permalink:"/Transition/solution-lessons",draft:!1,unlisted:!1,editUrl:"https://github.com/ibm-client-engineering/solution-filenet-aws/tree/main/packages/create-docusaurus/templates/shared/docs/4-Transition/lessons.md",tags:[],version:"current",sidebarPosition:1,frontMatter:{id:"solution-lessons",sidebar_position:1,title:"Lessons Learned"},sidebar:"tutorialSidebar",previous:{title:"Transition",permalink:"/category/transition"}},l={},c=[{value:"<strong>DynaTrace and FileNet</strong>",id:"dynatrace-and-filenet",level:3},{value:"<strong>The Problem</strong>",id:"the-problem",level:4},{value:"<strong>The Solution</strong>",id:"the-solution",level:4},{value:"Summary",id:"summary",level:4}];function d(e){const t={code:"code",h3:"h3",h4:"h4",img:"img",p:"p",pre:"pre",strong:"strong",...(0,o.a)(),...e.components};return(0,s.jsxs)(s.Fragment,{children:[(0,s.jsx)(t.p,{children:"Throughout our journey on this project, the team encountered many obstacles. This section will outline any errors, blockers, and setbacks the team faced. We will discuss how these blockers were identified and resolved."}),"\n",(0,s.jsx)(t.h3,{id:"dynatrace-and-filenet",children:(0,s.jsx)(t.strong,{children:"DynaTrace and FileNet"})}),"\n",(0,s.jsx)(t.h4,{id:"the-problem",children:(0,s.jsx)(t.strong,{children:"The Problem"})}),"\n",(0,s.jsx)(t.p,{children:"While setting up FileNet on EKS, one of the elements the team had to take into account was the client's use of DynaTrace. Dynatrace is a performance monitoring and application performance management (APM) solution that can be used to monitor and analyze the performance of applications and services. When Dynatrace is used in a Kubernetes environment, it typically involves deploying Dynatrace agents or components as sidecar containers or as part of your application's deployment. These agents collect data about the performance of your applications, containers, and Kubernetes infrastructure and send that data to the Dynatrace platform for analysis."}),"\n",(0,s.jsx)(t.p,{children:"During the initial setup of FileNet, the team was given a namespace that Dynatrace would be disabled in. The team was able to setup FileNet in this namespace and everything was working as intended. The FileNet containers were up and running in a healthy state for several weeks. The team was moving forward and completing use cases during this time. However, one day the team joined a session with the client and a large number of the pods were in CrashLoopBackoff."}),"\n",(0,s.jsx)(t.p,{children:(0,s.jsx)(t.img,{src:"https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/adcc307e-f0ea-4fda-9aa2-758d9c98e635",alt:"FileNet Lessons Learn 1.png"})}),"\n",(0,s.jsx)(t.p,{children:"The team tried all the usual troubleshooting steps like restarting the pods, scaling up and down the operator and other common troubleshooting steps. However, the crashing pods persisted and the team began to dig into the logs. After searching through several FileNet logs, the team looked through the logs of an init container associated with one of the failing pods. Here the team saw the following error:"}),"\n",(0,s.jsx)(t.pre,{children:(0,s.jsx)(t.code,{children:"cp: cannot open '/var/lib/dynatrace/oneagent/agent/config/deployment.conf' for reading: permission denied\ncp: cannot open '/var/lib/dynatrace/oneagent/agent/config/deploymentChangesDataBackup' for reading: permission denied\ncp: cannot access '/var/lib/dynatrace/oneagent/agent/watchdog': permission denied \n"})}),"\n",(0,s.jsx)(t.p,{children:"The team was able to find these logs using the following steps:"}),"\n",(0,s.jsx)(t.pre,{children:(0,s.jsx)(t.code,{children:"kubectl describe <NameOfFailingPod>\n"})}),"\n",(0,s.jsx)(t.p,{children:"In the output there should be an 'Init Containers' section that has the name of the init container."}),"\n",(0,s.jsx)(t.p,{children:(0,s.jsx)(t.img,{src:"https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/56736d1a-2cd4-4edd-9eaa-579e542a58d9",alt:"FileNet Lessons Learn 2.png"})}),"\n",(0,s.jsx)(t.p,{children:"We can now view the logs using the following command:"}),"\n",(0,s.jsx)(t.pre,{children:(0,s.jsx)(t.code,{children:"kubectl logs <NameOfFailingPod> -c <NameOfInitContainer>\n"})}),"\n",(0,s.jsx)(t.h4,{id:"the-solution",children:(0,s.jsx)(t.strong,{children:"The Solution"})}),"\n",(0,s.jsx)(t.p,{children:"Dynatrace requires write access to the filesystem of the host or container where it is running to function correctly. Dynatrace agents and components need to store data, logs, and configuration information, which typically requires write access to the filesystem. In our case, FileNet filesystem is set to read-only. The team could request the client make modifications to DynaTrace. However, these accommodations were made previously and there are no guarantees that future updates to the cluster wouldn't re-enable DynaTrace in the namespace. The easiest solution would be to allow DynaTrace read/write access to FileNet's filesystem. This would eliminate any future errors and allow the client to continue to monitor with DynaTrace."}),"\n",(0,s.jsx)(t.p,{children:"Earlier versions of FileNet have the filesystem set to read only by default. However, with the release of FileNet Version 5.5.11, FileNet deployments now have the option to set the filesystem to read/write."}),"\n",(0,s.jsx)(t.p,{children:"To accomplish this, we needed to update FileNet version 5.5.11 and then set the filesystem to read/write. For instructions on updating, please reference the upgrade section."}),"\n",(0,s.jsx)(t.p,{children:"Once FileNet is upgraded to 5.5.11, we can enable the read/write file system in the CR with the following line:"}),"\n",(0,s.jsx)(t.pre,{children:(0,s.jsx)(t.code,{children:"shared_configuration:\n  sc_disable_read_only_root_filesystem: true\n"})}),"\n",(0,s.jsx)(t.p,{children:"Now that the filesystem has been set to read/write, DynaTrace will no longer crash the pods."}),"\n",(0,s.jsx)(t.h4,{id:"summary",children:"Summary"}),"\n",(0,s.jsx)(t.p,{children:"DynaTrace requires a read/wite filesystem to operate correctly. FileNet has a read-only filesystem by default. The team upgraded to FileNet version 5.5.11 that has an option to disable read-only filesystem. This fixed the crashing pods."})]})}function h(e={}){const{wrapper:t}={...(0,o.a)(),...e.components};return t?(0,s.jsx)(t,{...e,children:(0,s.jsx)(d,{...e})}):d(e)}},1151:(e,t,n)=>{n.d(t,{Z:()=>r,a:()=>i});var s=n(7294);const o={},a=s.createContext(o);function i(e){const t=s.useContext(a);return s.useMemo((function(){return"function"==typeof e?e(t):{...t,...e}}),[t,e])}function r(e){let t;return t=e.disableParentContext?"function"==typeof e.components?e.components(o):e.components||o:i(e.components),s.createElement(a.Provider,{value:t},e.children)}}}]);