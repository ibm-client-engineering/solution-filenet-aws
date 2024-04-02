"use strict";(self.webpackChunkwebsite=self.webpackChunkwebsite||[]).push([[8837],{9566:(e,t,n)=>{n.r(t),n.d(t,{assets:()=>a,contentTitle:()=>o,default:()=>h,frontMatter:()=>l,metadata:()=>r,toc:()=>c});var i=n(5893),s=n(1151);const l={title:"Log - Sprint 5 \ud83d\udeeb",description:"Flight Log of Co-Creation Activities",slug:"flight-log-43",tags:["log","sprint"]},o=void 0,r={permalink:"/solution-filenet-aws/blog/flight-log-43",editUrl:"https://github.com/ibm-client-engineering/solution-filenet-aws/edit/main/flight-logs/2024-03-12-cocreate.md",source:"@site/flight-logs/2024-03-12-cocreate.md",title:"Log - Sprint 5 \ud83d\udeeb",description:"Flight Log of Co-Creation Activities",date:"2024-03-12T00:00:00.000Z",formattedDate:"March 12, 2024",tags:[{label:"log",permalink:"/solution-filenet-aws/blog/tags/log"},{label:"sprint",permalink:"/solution-filenet-aws/blog/tags/sprint"}],readingTime:1.415,hasTruncateMarker:!1,authors:[],frontMatter:{title:"Log - Sprint 5 \ud83d\udeeb",description:"Flight Log of Co-Creation Activities",slug:"flight-log-43",tags:["log","sprint"]},unlisted:!1,prevItem:{title:"Log - Sprint 6 \ud83d\udeeb",permalink:"/solution-filenet-aws/blog/flight-log-44"},nextItem:{title:"Log - Sprint 4 \ud83d\udeeb",permalink:"/solution-filenet-aws/blog/flight-log-42"}},a={authorsImageUrls:[]},c=[{value:"Date",id:"date",level:2},{value:"Key Accomplishments",id:"key-accomplishments",level:2},{value:"Work In Progress",id:"work-in-progress",level:2},{value:"Challenges",id:"challenges",level:2},{value:"Action Items",id:"action-items",level:2},{value:"Next Steps",id:"next-steps",level:2},{value:"Tracking",id:"tracking",level:2}];function d(e){const t={h2:"h2",li:"li",p:"p",strong:"strong",ul:"ul",...(0,s.a)(),...e.components};return(0,i.jsxs)(i.Fragment,{children:[(0,i.jsx)(t.h2,{id:"date",children:"Date"}),"\n",(0,i.jsx)(t.p,{children:"Flight Logs contain information relating to steps completed between 03/12/24 - 03/14/24"}),"\n",(0,i.jsx)(t.h2,{id:"key-accomplishments",children:"Key Accomplishments"}),"\n",(0,i.jsxs)(t.ul,{children:["\n",(0,i.jsx)(t.li,{children:"Client is setting up their AWS gov cloud environment in parallel. Overall the steps in this solution guide worked well for AWS gov cloud."}),"\n",(0,i.jsx)(t.li,{children:"Guided client on how to add css index area for another object store. In the css sections under 'initialize_configuration'need index area per OS."}),"\n"]}),"\n",(0,i.jsx)(t.h2,{id:"work-in-progress",children:"Work In Progress"}),"\n",(0,i.jsxs)(t.ul,{children:["\n",(0,i.jsx)(t.li,{children:"Walked through running the commands to check which file storage the index areas map to. (eg: how /opt/ibm/indexareas maps to efs)"}),"\n",(0,i.jsx)(t.li,{children:"Went through cert manager setup."}),"\n",(0,i.jsx)(t.li,{children:"Working with support team to resolve IER deployment failure."}),"\n"]}),"\n",(0,i.jsx)(t.h2,{id:"challenges",children:"Challenges"}),"\n",(0,i.jsxs)(t.ul,{children:["\n",(0,i.jsxs)(t.li,{children:["\n",(0,i.jsxs)(t.p,{children:[(0,i.jsx)(t.strong,{children:"Ceritficate issue:"}),"  PD - Security configuration, says not secure and certificate not valid on all the urls.\nTook a closer look at cert setup- matched tls secret name with the private secret key ref. Cert still did not come up after doing this.\nFQDN is not filled out, discussed options."]}),"\n"]}),"\n",(0,i.jsxs)(t.li,{children:["\n",(0,i.jsxs)(t.p,{children:[(0,i.jsx)(t.strong,{children:"IER Image:"})," Client is getting Back off error message for IER pod."]}),"\n"]}),"\n"]}),"\n",(0,i.jsx)(t.h2,{id:"action-items",children:"Action Items"}),"\n",(0,i.jsxs)(t.ul,{children:["\n",(0,i.jsx)(t.li,{children:"Track the case TS015679454 and resolve the issue."}),"\n",(0,i.jsx)(t.li,{children:"Look into s3 config without access keys - enhancement request was approved by product team last year. It improves content replication setup."}),"\n"]}),"\n",(0,i.jsx)(t.h2,{id:"next-steps",children:"Next Steps"}),"\n",(0,i.jsxs)(t.ul,{children:["\n",(0,i.jsx)(t.li,{children:"Look into the certificate setup and recommend next steps, including any other fields in the YAML that have to be filled."}),"\n",(0,i.jsx)(t.li,{children:"Check if cert is now valid from ICN, etc. If so, reimport cert into keystore and retry launching PD."}),"\n",(0,i.jsx)(t.li,{children:"Continuing to track the IER image pull issue support case. Deploy IBM Enterprise Record and TM pod setup for IER."}),"\n"]}),"\n",(0,i.jsx)(t.h2,{id:"tracking",children:"Tracking"}),"\n",(0,i.jsx)(t.p,{children:(0,i.jsx)(t.strong,{children:"Cases open: 1"})}),"\n",(0,i.jsxs)(t.ul,{children:["\n",(0,i.jsx)(t.li,{children:"Case TS015679454"}),"\n"]})]})}function h(e={}){const{wrapper:t}={...(0,s.a)(),...e.components};return t?(0,i.jsx)(t,{...e,children:(0,i.jsx)(d,{...e})}):d(e)}},1151:(e,t,n)=>{n.d(t,{Z:()=>r,a:()=>o});var i=n(7294);const s={},l=i.createContext(s);function o(e){const t=i.useContext(l);return i.useMemo((function(){return"function"==typeof e?e(t):{...t,...e}}),[t,e])}function r(e){let t;return t=e.disableParentContext?"function"==typeof e.components?e.components(s):e.components||s:o(e.components),i.createElement(l.Provider,{value:t},e.children)}}}]);