"use strict";(self.webpackChunkwebsite=self.webpackChunkwebsite||[]).push([[5690],{3905:(e,t,n)=>{n.d(t,{Zo:()=>c,kt:()=>f});var r=n(7294);function l(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function i(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);t&&(r=r.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,r)}return n}function o(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?i(Object(n),!0).forEach((function(t){l(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):i(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function a(e,t){if(null==e)return{};var n,r,l=function(e,t){if(null==e)return{};var n,r,l={},i=Object.keys(e);for(r=0;r<i.length;r++)n=i[r],t.indexOf(n)>=0||(l[n]=e[n]);return l}(e,t);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);for(r=0;r<i.length;r++)n=i[r],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(l[n]=e[n])}return l}var s=r.createContext({}),u=function(e){var t=r.useContext(s),n=t;return e&&(n="function"==typeof e?e(t):o(o({},t),e)),n},c=function(e){var t=u(e.components);return r.createElement(s.Provider,{value:t},e.children)},p="mdxType",g={inlineCode:"code",wrapper:function(e){var t=e.children;return r.createElement(r.Fragment,{},t)}},m=r.forwardRef((function(e,t){var n=e.components,l=e.mdxType,i=e.originalType,s=e.parentName,c=a(e,["components","mdxType","originalType","parentName"]),p=u(n),m=l,f=p["".concat(s,".").concat(m)]||p[m]||g[m]||i;return n?r.createElement(f,o(o({ref:t},c),{},{components:n})):r.createElement(f,o({ref:t},c))}));function f(e,t){var n=arguments,l=t&&t.mdxType;if("string"==typeof e||l){var i=n.length,o=new Array(i);o[0]=m;var a={};for(var s in t)hasOwnProperty.call(t,s)&&(a[s]=t[s]);a.originalType=e,a[p]="string"==typeof e?e:l,o[1]=a;for(var u=2;u<i;u++)o[u]=n[u];return r.createElement.apply(null,o)}return r.createElement.apply(null,n)}m.displayName="MDXCreateElement"},6874:(e,t,n)=>{n.r(t),n.d(t,{assets:()=>s,contentTitle:()=>o,default:()=>g,frontMatter:()=>i,metadata:()=>a,toc:()=>u});var r=n(7462),l=(n(7294),n(3905));const i={title:"Log - Sprint 27 \ud83d\udeeb",description:"Flight Log of Co-Creation Activities",slug:"flight-log-27",tags:["log","sprint"]},o=void 0,a={permalink:"/solution-filenet-aws/blog/flight-log-27",editUrl:"https://github.com/ibm-client-engineering/solution-filenet-aws/edit/main/flight-logs/2023-10-25-cocreate.md",source:"@site/flight-logs/2023-10-25-cocreate.md",title:"Log - Sprint 27 \ud83d\udeeb",description:"Flight Log of Co-Creation Activities",date:"2023-10-25T00:00:00.000Z",formattedDate:"October 25, 2023",tags:[{label:"log",permalink:"/solution-filenet-aws/blog/tags/log"},{label:"sprint",permalink:"/solution-filenet-aws/blog/tags/sprint"}],readingTime:.645,hasTruncateMarker:!1,authors:[],frontMatter:{title:"Log - Sprint 27 \ud83d\udeeb",description:"Flight Log of Co-Creation Activities",slug:"flight-log-27",tags:["log","sprint"]},prevItem:{title:"Log - Sprint 28 \ud83d\udeeb",permalink:"/solution-filenet-aws/blog/flight-log-28"},nextItem:{title:"Log - Sprint 26 \ud83d\udeeb",permalink:"/solution-filenet-aws/blog/flight-log-26"}},s={authorsImageUrls:[]},u=[{value:"Work in Progress",id:"work-in-progress",level:2},{value:"Currently Tracking",id:"currently-tracking",level:2},{value:"Next Steps",id:"next-steps",level:2},{value:"Tracking",id:"tracking",level:2}],c={toc:u},p="wrapper";function g(e){let{components:t,...n}=e;return(0,l.kt)(p,(0,r.Z)({},c,n,{components:t,mdxType:"MDXLayout"}),(0,l.kt)("h2",{id:"work-in-progress"},"Work in Progress"),(0,l.kt)("ul",null,(0,l.kt)("li",{parentName:"ul"},"Today the team continued to upgrade the client\u2019s FileNet environment to version 5.5.11."),(0,l.kt)("li",{parentName:"ul"},"During the session, the team was able to successfully update the operator."),(0,l.kt)("li",{parentName:"ul"},"The team then updated the CR to reflect the new image tags and added the \u2018sc_disable_read_only_root_filesystem\u2019 variable.")),(0,l.kt)("h2",{id:"currently-tracking"},"Currently Tracking"),(0,l.kt)("ul",null,(0,l.kt)("li",{parentName:"ul"},"The client is watching to see if the rolling update of the running pods is successful."),(0,l.kt)("li",{parentName:"ul"},"We will continue to work closely with IBM support.")),(0,l.kt)("h2",{id:"next-steps"},"Next Steps"),(0,l.kt)("ul",null,(0,l.kt)("li",{parentName:"ul"},(0,l.kt)("p",{parentName:"li"},"The team will assess the state of the cluster and move to resolve any remaining errors."),(0,l.kt)("ul",{parentName:"li"},(0,l.kt)("li",{parentName:"ul"},(0,l.kt)("a",{parentName:"li",href:"https://trello.com/c/o1nc3JXp/1-cluster-and-database-troubleshooting"},"ibm-client-engineering/solution-filenet-aws")),(0,l.kt)("li",{parentName:"ul"},'This flight log is being submitted via PR "10/30/2023 Documentation"')))),(0,l.kt)("h2",{id:"tracking"},"Tracking"),(0,l.kt)("p",null,(0,l.kt)("strong",{parentName:"p"},"Cases open: 1")),(0,l.kt)("ul",null,(0,l.kt)("li",{parentName:"ul"},"Case TS014370797")),(0,l.kt)("p",null,(0,l.kt)("strong",{parentName:"p"},"Cases closed: 2")),(0,l.kt)("ul",null,(0,l.kt)("li",{parentName:"ul"},"Case TS014232963"),(0,l.kt)("li",{parentName:"ul"},"Case TS014348824")))}g.isMDXComponent=!0}}]);