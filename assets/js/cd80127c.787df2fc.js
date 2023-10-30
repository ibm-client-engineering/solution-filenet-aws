"use strict";(self.webpackChunkwebsite=self.webpackChunkwebsite||[]).push([[9154],{3905:(e,t,n)=>{n.d(t,{Zo:()=>u,kt:()=>f});var i=n(7294);function r(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function a(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);t&&(i=i.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,i)}return n}function l(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?a(Object(n),!0).forEach((function(t){r(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):a(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function o(e,t){if(null==e)return{};var n,i,r=function(e,t){if(null==e)return{};var n,i,r={},a=Object.keys(e);for(i=0;i<a.length;i++)n=a[i],t.indexOf(n)>=0||(r[n]=e[n]);return r}(e,t);if(Object.getOwnPropertySymbols){var a=Object.getOwnPropertySymbols(e);for(i=0;i<a.length;i++)n=a[i],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(r[n]=e[n])}return r}var s=i.createContext({}),c=function(e){var t=i.useContext(s),n=t;return e&&(n="function"==typeof e?e(t):l(l({},t),e)),n},u=function(e){var t=c(e.components);return i.createElement(s.Provider,{value:t},e.children)},p="mdxType",g={inlineCode:"code",wrapper:function(e){var t=e.children;return i.createElement(i.Fragment,{},t)}},d=i.forwardRef((function(e,t){var n=e.components,r=e.mdxType,a=e.originalType,s=e.parentName,u=o(e,["components","mdxType","originalType","parentName"]),p=c(n),d=r,f=p["".concat(s,".").concat(d)]||p[d]||g[d]||a;return n?i.createElement(f,l(l({ref:t},u),{},{components:n})):i.createElement(f,l({ref:t},u))}));function f(e,t){var n=arguments,r=t&&t.mdxType;if("string"==typeof e||r){var a=n.length,l=new Array(a);l[0]=d;var o={};for(var s in t)hasOwnProperty.call(t,s)&&(o[s]=t[s]);o.originalType=e,o[p]="string"==typeof e?e:r,l[1]=o;for(var c=2;c<a;c++)l[c]=n[c];return i.createElement.apply(null,l)}return i.createElement.apply(null,n)}d.displayName="MDXCreateElement"},9340:(e,t,n)=>{n.r(t),n.d(t,{assets:()=>s,contentTitle:()=>l,default:()=>g,frontMatter:()=>a,metadata:()=>o,toc:()=>c});var i=n(7462),r=(n(7294),n(3905));const a={title:"Log - Sprint 7 \ud83d\udeeb",description:"Flight Log of Co-Creation Activities",slug:"flight-log-7",tags:["log","sprint"]},l=void 0,o={permalink:"/solution-filenet-aws/blog/flight-log-7",editUrl:"https://github.com/ibm-client-engineering/solution-filenet-aws/edit/main/flight-logs/2023-06-06-cocreate.md",source:"@site/flight-logs/2023-06-06-cocreate.md",title:"Log - Sprint 7 \ud83d\udeeb",description:"Flight Log of Co-Creation Activities",date:"2023-06-06T00:00:00.000Z",formattedDate:"June 6, 2023",tags:[{label:"log",permalink:"/solution-filenet-aws/blog/tags/log"},{label:"sprint",permalink:"/solution-filenet-aws/blog/tags/sprint"}],readingTime:1.385,hasTruncateMarker:!1,authors:[],frontMatter:{title:"Log - Sprint 7 \ud83d\udeeb",description:"Flight Log of Co-Creation Activities",slug:"flight-log-7",tags:["log","sprint"]},prevItem:{title:"Log - Sprint 8 \ud83d\udeeb",permalink:"/solution-filenet-aws/blog/flight-log-8"},nextItem:{title:"Log - Sprint 6 \ud83d\udeeb",permalink:"/solution-filenet-aws/blog/flight-log-6"}},s={authorsImageUrls:[]},c=[{value:"Date",id:"date",level:2},{value:"Key Accomplishments",id:"key-accomplishments",level:2},{value:"Challenges",id:"challenges",level:2},{value:"Action Items",id:"action-items",level:2},{value:"Tracking",id:"tracking",level:2}],u={toc:c},p="wrapper";function g(e){let{components:t,...n}=e;return(0,r.kt)(p,(0,i.Z)({},u,n,{components:t,mdxType:"MDXLayout"}),(0,r.kt)("h2",{id:"date"},"Date"),(0,r.kt)("p",null,"Flight Log contain information relating to steps completed on 06/06/2023"),(0,r.kt)("h2",{id:"key-accomplishments"},"Key Accomplishments"),(0,r.kt)("ul",null,(0,r.kt)("li",{parentName:"ul"},"Successfully edited the CR with our certificate secret.\xa0 The Ingress needs to have a certificate in its trust store, so we forced it to redo and recreate secrets to include the certificate. To do this we used the Ingress secret \u2018filenet-poc-tls\u2019 that we created before and added it to the CR at the line \u2018sc_ingress_tls_secret_name\u2019. We also added it to the trusted certificate list within the CR."),(0,r.kt)("li",{parentName:"ul"},"Deleted and recreated the \u2018fncmdeploy-fncm-custom-ssl-secret\u2019 and \u2018fncmdeploy-ban-custom-ssl-secret\u2019."),(0,r.kt)("li",{parentName:"ul"},"We edited the resource quota and upgraded it from \u2018large\u2019 to \u2018x-large\u2019.\xa0 Edited the Value.yaml through GitHub and sent in a PR with the change (could not change it from command line because we got authorization issues)."),(0,r.kt)("li",{parentName:"ul"},"We set the replica count of the Navigator back to 2 and all pods were up and running.")),(0,r.kt)("h2",{id:"challenges"},"Challenges"),(0,r.kt)("ul",null,(0,r.kt)("li",{parentName:"ul"},"We initially received an error when trying to visit the ACCE URL. This was fixed after we added the certificate secret to the CR and reapplied it."),(0,r.kt)("li",{parentName:"ul"},"We are still having issues logging in to ACCE and Navigator even after applying the certificate secret to the CR and redeploying pods.")),(0,r.kt)("h2",{id:"action-items"},"Action Items"),(0,r.kt)("ul",null,(0,r.kt)("li",{parentName:"ul"},"We followed the steps laid out by IBM Dev team but are still running into the Ingress issue of having a blank page after logging into ACCE and not being able to login to the Navigator.\xa0 We exported Ansible logs and will bring it back to the IBM Dev team to see what the issue could be.")),(0,r.kt)("h2",{id:"tracking"},"Tracking"),(0,r.kt)("ul",null,(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("a",{parentName:"li",href:"https://www.ibm.com/mysupport/s/case/5003p00002iwdgWAAQ/filenet-container-deployment-to-eks"},"TS013093278")),(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("a",{parentName:"li",href:"https://zenhub.ibm.com/workspaces/st5-action-information-center-64343620d0cfd0000f03a114/issues/ibm-client-engineering/solution-filenet-aws/8"},"ibm-client-engineering/solution-filenet-aws#8")),(0,r.kt)("li",{parentName:"ul"},"Flight log was added by PR 06-06-2023")))}g.isMDXComponent=!0}}]);