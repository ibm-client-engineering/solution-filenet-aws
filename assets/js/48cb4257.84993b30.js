"use strict";(self.webpackChunkwebsite=self.webpackChunkwebsite||[]).push([[624],{8763:(e,t,n)=>{n.r(t),n.d(t,{assets:()=>a,contentTitle:()=>o,default:()=>h,frontMatter:()=>s,metadata:()=>r,toc:()=>c});var i=n(5893),l=n(1151);const s={title:"Log - Sprint 38 \ud83d\udeeb",description:"Flight Log of Co-Creation Activities",slug:"flight-log-38",tags:["log","sprint"]},o=void 0,r={permalink:"/solution-filenet-aws/blog/flight-log-38",editUrl:"https://github.com/ibm-client-engineering/solution-filenet-aws/edit/main/flight-logs/2023-11-17-cocreate.md",source:"@site/flight-logs/2023-11-17-cocreate.md",title:"Log - Sprint 38 \ud83d\udeeb",description:"Flight Log of Co-Creation Activities",date:"2023-11-17T00:00:00.000Z",formattedDate:"November 17, 2023",tags:[{label:"log",permalink:"/solution-filenet-aws/blog/tags/log"},{label:"sprint",permalink:"/solution-filenet-aws/blog/tags/sprint"}],readingTime:.715,hasTruncateMarker:!1,authors:[],frontMatter:{title:"Log - Sprint 38 \ud83d\udeeb",description:"Flight Log of Co-Creation Activities",slug:"flight-log-38",tags:["log","sprint"]},unlisted:!1,prevItem:{title:"Log - Sprint 1 \ud83d\udeeb",permalink:"/solution-filenet-aws/blog/flight-log-1"},nextItem:{title:"Log - Sprint 37 \ud83d\udeeb",permalink:"/solution-filenet-aws/blog/flight-log-37"}},a={authorsImageUrls:[]},c=[{value:"Work in Progress",id:"work-in-progress",level:2},{value:"Currently Tracking",id:"currently-tracking",level:2},{value:"Next Steps",id:"next-steps",level:2},{value:"Tracking",id:"tracking",level:2}];function d(e){const t={a:"a",h2:"h2",li:"li",p:"p",strong:"strong",ul:"ul",...(0,l.a)(),...e.components};return(0,i.jsxs)(i.Fragment,{children:[(0,i.jsx)(t.h2,{id:"work-in-progress",children:"Work in Progress"}),"\n",(0,i.jsxs)(t.ul,{children:["\n",(0,i.jsx)(t.li,{children:"The team scaled the FNCM operator down to 0 and set readOnlyRootFilesystem to false in the IER deployment directly."}),"\n",(0,i.jsx)(t.li,{children:"The team then added explicit Dynatrace annotations to the IER deployment that were supposed to disable the agent injection."}),"\n",(0,i.jsx)(t.li,{children:"We then modified the daemonset for Dynatrace to scale it to 0. After applying this change, the IER pods came online."}),"\n"]}),"\n",(0,i.jsx)(t.h2,{id:"currently-tracking",children:"Currently Tracking"}),"\n",(0,i.jsxs)(t.ul,{children:["\n",(0,i.jsx)(t.li,{children:"The client will verify the IER pod comes up again after scaling the FNCM operator back up."}),"\n"]}),"\n",(0,i.jsx)(t.h2,{id:"next-steps",children:"Next Steps"}),"\n",(0,i.jsxs)(t.ul,{children:["\n",(0,i.jsxs)(t.li,{children:["\n",(0,i.jsx)(t.p,{children:"The team will examine the state of the IER deployment and will move to resume use cases and demos."}),"\n",(0,i.jsxs)(t.ul,{children:["\n",(0,i.jsx)(t.li,{children:(0,i.jsx)(t.a,{href:"https://trello.com/c/3WHHYbfl/3-functionality-verification",children:"ibm-client-engineering/solution-filenet-aws"})}),"\n",(0,i.jsx)(t.li,{children:'This flight log is being submitted via PR "11/21/2023 Documentation"'}),"\n"]}),"\n"]}),"\n"]}),"\n",(0,i.jsx)(t.h2,{id:"tracking",children:"Tracking"}),"\n",(0,i.jsx)(t.p,{children:(0,i.jsx)(t.strong,{children:"Cases open: 1"})}),"\n",(0,i.jsxs)(t.ul,{children:["\n",(0,i.jsx)(t.li,{children:"Case TS014753369"}),"\n"]}),"\n",(0,i.jsx)(t.p,{children:(0,i.jsx)(t.strong,{children:"Cases closed: 3"})}),"\n",(0,i.jsxs)(t.ul,{children:["\n",(0,i.jsx)(t.li,{children:"Case TS014232963"}),"\n",(0,i.jsx)(t.li,{children:"Case TS014348824"}),"\n",(0,i.jsx)(t.li,{children:"Case TS014370797"}),"\n"]})]})}function h(e={}){const{wrapper:t}={...(0,l.a)(),...e.components};return t?(0,i.jsx)(t,{...e,children:(0,i.jsx)(d,{...e})}):d(e)}},1151:(e,t,n)=>{n.d(t,{Z:()=>r,a:()=>o});var i=n(7294);const l={},s=i.createContext(l);function o(e){const t=i.useContext(s);return i.useMemo((function(){return"function"==typeof e?e(t):{...t,...e}}),[t,e])}function r(e){let t;return t=e.disableParentContext?"function"==typeof e.components?e.components(l):e.components||l:o(e.components),i.createElement(s.Provider,{value:t},e.children)}}}]);