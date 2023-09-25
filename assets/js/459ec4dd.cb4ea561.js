"use strict";(self.webpackChunkwebsite=self.webpackChunkwebsite||[]).push([[4649],{3905:(e,t,n)=>{n.d(t,{Zo:()=>u,kt:()=>m});var r=n(7294);function o(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function i(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);t&&(r=r.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,r)}return n}function a(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?i(Object(n),!0).forEach((function(t){o(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):i(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function l(e,t){if(null==e)return{};var n,r,o=function(e,t){if(null==e)return{};var n,r,o={},i=Object.keys(e);for(r=0;r<i.length;r++)n=i[r],t.indexOf(n)>=0||(o[n]=e[n]);return o}(e,t);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);for(r=0;r<i.length;r++)n=i[r],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(o[n]=e[n])}return o}var s=r.createContext({}),c=function(e){var t=r.useContext(s),n=t;return e&&(n="function"==typeof e?e(t):a(a({},t),e)),n},u=function(e){var t=c(e.components);return r.createElement(s.Provider,{value:t},e.children)},p="mdxType",g={inlineCode:"code",wrapper:function(e){var t=e.children;return r.createElement(r.Fragment,{},t)}},h=r.forwardRef((function(e,t){var n=e.components,o=e.mdxType,i=e.originalType,s=e.parentName,u=l(e,["components","mdxType","originalType","parentName"]),p=c(n),h=o,m=p["".concat(s,".").concat(h)]||p[h]||g[h]||i;return n?r.createElement(m,a(a({ref:t},u),{},{components:n})):r.createElement(m,a({ref:t},u))}));function m(e,t){var n=arguments,o=t&&t.mdxType;if("string"==typeof e||o){var i=n.length,a=new Array(i);a[0]=h;var l={};for(var s in t)hasOwnProperty.call(t,s)&&(l[s]=t[s]);l.originalType=e,l[p]="string"==typeof e?e:o,a[1]=l;for(var c=2;c<i;c++)a[c]=n[c];return r.createElement.apply(null,a)}return r.createElement.apply(null,n)}h.displayName="MDXCreateElement"},8924:(e,t,n)=>{n.r(t),n.d(t,{assets:()=>s,contentTitle:()=>a,default:()=>g,frontMatter:()=>i,metadata:()=>l,toc:()=>c});var r=n(7462),o=(n(7294),n(3905));const i={title:"Log - Sprint 2 \ud83d\udeeb",description:"Flight Log of Co-Creation Activities",slug:"flight-log-2",tags:["log","sprint"]},a=void 0,l={permalink:"/solution-filenet-aws/blog/flight-log-2",editUrl:"https://github.com/ibm-client-engineering/solution-filenet-aws/edit/main/flight-logs/2023-05-09-cocreate.md",source:"@site/flight-logs/2023-05-09-cocreate.md",title:"Log - Sprint 2 \ud83d\udeeb",description:"Flight Log of Co-Creation Activities",date:"2023-05-09T00:00:00.000Z",formattedDate:"May 9, 2023",tags:[{label:"log",permalink:"/solution-filenet-aws/blog/tags/log"},{label:"sprint",permalink:"/solution-filenet-aws/blog/tags/sprint"}],readingTime:1.94,hasTruncateMarker:!1,authors:[],frontMatter:{title:"Log - Sprint 2 \ud83d\udeeb",description:"Flight Log of Co-Creation Activities",slug:"flight-log-2",tags:["log","sprint"]},prevItem:{title:"Log - Sprint 3 \ud83d\udeeb",permalink:"/solution-filenet-aws/blog/flight-log-3"},nextItem:{title:"Log - Sprint 1 \ud83d\udeeb",permalink:"/solution-filenet-aws/blog/flight-log-1"}},s={authorsImageUrls:[]},c=[{value:"Date",id:"date",level:2},{value:"Key Accomplishments",id:"key-accomplishments",level:2},{value:"Challenges",id:"challenges",level:2},{value:"Lessons Learned",id:"lessons-learned",level:2},{value:"Action Items",id:"action-items",level:2},{value:"Up Next",id:"up-next",level:2}],u={toc:c},p="wrapper";function g(e){let{components:t,...n}=e;return(0,o.kt)(p,(0,r.Z)({},u,n,{components:t,mdxType:"MDXLayout"}),(0,o.kt)("h2",{id:"date"},"Date"),(0,o.kt)("p",null,"Flight Logs contain information relating to steps completed between 05/09 - 05/12"),(0,o.kt)("h2",{id:"key-accomplishments"},"Key Accomplishments"),(0,o.kt)("ul",null,(0,o.kt)("li",{parentName:"ul"},"Worked with engineering to fix the resource issues with the original operator build and successfully deployed operator with correct resources sizes."),(0,o.kt)("li",{parentName:"ul"},"Successfully applied CR to point to the correct repo for navigator image after patching daemonset."),(0,o.kt)("li",{parentName:"ul"},"Successfully got the Ingress to work and connect to the host through the browser on a secure connection.")),(0,o.kt)("h2",{id:"challenges"},"Challenges"),(0,o.kt)("ul",null,(0,o.kt)("li",{parentName:"ul"},"This customer environment requires the resource restrictions set into any container spun up. The temporary job pod which uses the operator limit does not contain any mechanism to set these restrictions."),(0,o.kt)("li",{parentName:"ul"},"The customer was having issues accessing the newly made Operator image, due to registry access permissions. We had to push image to a public registry with the tag trv2202 for the customer to pull and then have them push it to their own private registry."),(0,o.kt)("li",{parentName:"ul"},"We had issues bringing the Filenet pods online after successfully getting the new Operator image in the client environment."),(0,o.kt)("li",{parentName:"ul"},"Folder-prepare-container kept erroring out due to us implementing a readOnlyRootFilesystem and prevented Dynatrace."),(0,o.kt)("li",{parentName:"ul"},"We had issues connecting to the host through the browser when trying to get the Ingress to work.  We thought this was due to the host name being in the wrong location in the YAML file, but it was actually due to the route 53 external DNS operator taking some time to pick everything up.")),(0,o.kt)("h2",{id:"lessons-learned"},"Lessons Learned"),(0,o.kt)("ul",null,(0,o.kt)("li",{parentName:"ul"},"Operator deployment takes care of requesting resources for new containers. Operator deployment creates an initialization container that spins up and it does not have the ability to set up CPU and memory limits. In the future, managing resources in environment can take care of this issue."),(0,o.kt)("li",{parentName:"ul"},"When applying the Ingress, give the route 53 DNS operator time to pick up the correct host name before trying to access it through the browser."),(0,o.kt)("li",{parentName:"ul"},'When accessing the host, we need to create a certificate to give it a secure connection.  This will prevent any "insecure connection" connection loops. ')),(0,o.kt)("h2",{id:"action-items"},"Action Items"),(0,o.kt)("ul",null,(0,o.kt)("li",{parentName:"ul"},"Followup with engineering to allow RW root fs to allow Dynatrace to work")),(0,o.kt)("h2",{id:"up-next"},"Up Next"),(0,o.kt)("ul",null,(0,o.kt)("li",{parentName:"ul"},"Use the Operator to bootstrap the gcd domain and object store and then create a navigator desktop using the CR file.")))}g.isMDXComponent=!0}}]);