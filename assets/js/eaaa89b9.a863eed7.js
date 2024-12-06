"use strict";(self.webpackChunkwebsite=self.webpackChunkwebsite||[]).push([[8033],{3818:(e,t,n)=>{n.r(t),n.d(t,{assets:()=>a,contentTitle:()=>o,default:()=>h,frontMatter:()=>l,metadata:()=>r,toc:()=>c});var i=n(5893),s=n(1151);const l={title:"Log - Sprint 2 \ud83d\udeeb",description:"Flight Log of Co-Creation Activities",slug:"flight-log-40",tags:["log","sprint"]},o=void 0,r={permalink:"/solution-filenet-aws/blog/flight-log-40",editUrl:"https://github.com/ibm-client-engineering/solution-filenet-aws/edit/main/flight-logs/2024-02-20-cocreate.md",source:"@site/flight-logs/2024-02-20-cocreate.md",title:"Log - Sprint 2 \ud83d\udeeb",description:"Flight Log of Co-Creation Activities",date:"2024-02-20T00:00:00.000Z",formattedDate:"February 20, 2024",tags:[{label:"log",permalink:"/solution-filenet-aws/blog/tags/log"},{label:"sprint",permalink:"/solution-filenet-aws/blog/tags/sprint"}],readingTime:1.185,hasTruncateMarker:!1,authors:[],frontMatter:{title:"Log - Sprint 2 \ud83d\udeeb",description:"Flight Log of Co-Creation Activities",slug:"flight-log-40",tags:["log","sprint"]},unlisted:!1,prevItem:{title:"Log - Sprint 3 \ud83d\udeeb",permalink:"/solution-filenet-aws/blog/flight-log-41"},nextItem:{title:"Log - Sprint 1 \ud83d\udeeb",permalink:"/solution-filenet-aws/blog/flight-log-39"}},a={authorsImageUrls:[]},c=[{value:"Date",id:"date",level:2},{value:"Key Accomplishments",id:"key-accomplishments",level:2},{value:"Challenges",id:"challenges",level:2},{value:"Lessons Learned",id:"lessons-learned",level:2},{value:"Action Items",id:"action-items",level:2},{value:"Next Steps",id:"next-steps",level:2},{value:"Tracking",id:"tracking",level:2}];function d(e){const t={h2:"h2",li:"li",p:"p",strong:"strong",ul:"ul",...(0,s.a)(),...e.components};return(0,i.jsxs)(i.Fragment,{children:[(0,i.jsx)(t.h2,{id:"date",children:"Date"}),"\n",(0,i.jsx)(t.p,{children:"Flight Logs contain information relating to steps completed between 02/20/24 - 02/22/24"}),"\n",(0,i.jsx)(t.h2,{id:"key-accomplishments",children:"Key Accomplishments"}),"\n",(0,i.jsxs)(t.ul,{children:["\n",(0,i.jsx)(t.li,{children:"Client scripted certain steps which should help if EKS cluster has to be reprovisioned and we need to redo the installation."}),"\n"]}),"\n",(0,i.jsx)(t.h2,{id:"challenges",children:"Challenges"}),"\n",(0,i.jsxs)(t.ul,{children:["\n",(0,i.jsxs)(t.li,{children:[(0,i.jsx)(t.strong,{children:"EKS Cluster clean up :"})," Client environment has a clean up process that deletes EKS cluster to save cost. Some of the resources in EKS failed to delete during this process. Client had to spend most of the week to create a new cluster and run through what we did the previous week."]}),"\n"]}),"\n",(0,i.jsx)(t.h2,{id:"lessons-learned",children:"Lessons Learned"}),"\n",(0,i.jsxs)(t.ul,{children:["\n",(0,i.jsx)(t.li,{children:"Try to script/automate most of the steps to speed up the process if we run into issues like cluster deletion"}),"\n",(0,i.jsx)(t.li,{children:"Database connection over SSL in CRD is disabled since we follow a MVP mode. In a production deployment client can set it up for more security."}),"\n"]}),"\n",(0,i.jsx)(t.h2,{id:"action-items",children:"Action Items"}),"\n",(0,i.jsxs)(t.ul,{children:["\n",(0,i.jsx)(t.li,{children:"Client wants to know how to move their environment specific data into the extracted case package in an upgrade scenario."}),"\n",(0,i.jsx)(t.li,{children:"Any best practices and guidelines we can recommend on moving secrets to aws, etc in a production setting for security purposes."}),"\n",(0,i.jsx)(t.li,{children:"Research egress part in CR. For the time being we kept that section but set the sc_restricted_internet_access: false"}),"\n",(0,i.jsx)(t.li,{children:"Documented differences in CR in the new case file."}),"\n"]}),"\n",(0,i.jsx)(t.h2,{id:"next-steps",children:"Next Steps"}),"\n",(0,i.jsxs)(t.ul,{children:["\n",(0,i.jsx)(t.li,{children:"Go through the FNCM CRD and fill out the configuration."}),"\n"]}),"\n",(0,i.jsx)(t.h2,{id:"tracking",children:"Tracking"})]})}function h(e={}){const{wrapper:t}={...(0,s.a)(),...e.components};return t?(0,i.jsx)(t,{...e,children:(0,i.jsx)(d,{...e})}):d(e)}},1151:(e,t,n)=>{n.d(t,{Z:()=>r,a:()=>o});var i=n(7294);const s={},l=i.createContext(s);function o(e){const t=i.useContext(l);return i.useMemo((function(){return"function"==typeof e?e(t):{...t,...e}}),[t,e])}function r(e){let t;return t=e.disableParentContext?"function"==typeof e.components?e.components(s):e.components||s:o(e.components),i.createElement(l.Provider,{value:t},e.children)}}}]);