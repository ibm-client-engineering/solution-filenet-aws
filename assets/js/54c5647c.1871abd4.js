"use strict";(self.webpackChunkwebsite=self.webpackChunkwebsite||[]).push([[4505],{3380:(c,e,a)=>{a.r(e),a.d(e,{assets:()=>t,contentTitle:()=>i,default:()=>d,frontMatter:()=>r,metadata:()=>o,toc:()=>s});var p=a(5893),n=a(1151);const r={id:"solution-stage-image-prep",sidebar_position:2,title:"Image Pre-Staging"},i=void 0,o={id:"Prepare/Stage/solution-stage-image-prep",title:"Image Pre-Staging",description:"Container Image preparation",source:"@site/docs/2-Prepare/Stage/Images.mdx",sourceDirName:"2-Prepare/Stage",slug:"/Prepare/Stage/solution-stage-image-prep",permalink:"/solution-filenet-aws/Prepare/Stage/solution-stage-image-prep",draft:!1,unlisted:!1,editUrl:"https://github.com/ibm-client-engineering/solution-filenet-aws/tree/main/packages/create-docusaurus/templates/shared/docs/2-Prepare/Stage/Images.mdx",tags:[],version:"current",sidebarPosition:2,frontMatter:{id:"solution-stage-image-prep",sidebar_position:2,title:"Image Pre-Staging"},sidebar:"tutorialSidebar",previous:{title:"Pre-Requisites",permalink:"/solution-filenet-aws/Prepare/Stage/solution-stage-pre-reqs"},next:{title:"AWS Account and Client",permalink:"/solution-filenet-aws/Prepare/Stage/solution-stage-aws"}},t={},s=[{value:"Container Image preparation",id:"container-image-preparation",level:2}];function l(c){const e={a:"a",admonition:"admonition",code:"code",h2:"h2",p:"p",pre:"pre",...(0,n.a)(),...c.components};return(0,p.jsxs)(p.Fragment,{children:[(0,p.jsx)(e.h2,{id:"container-image-preparation",children:"Container Image preparation"}),"\n",(0,p.jsx)(e.admonition,{type:"note",children:(0,p.jsx)(e.p,{children:"If there is a requirement to pre-stage the FileNet images whether in a private registry or airgapped installs, the following steps should be taken. Otherwise the images will be pulled down from the IBM Registry."})}),"\n",(0,p.jsx)(e.p,{children:"First retrieve your IBM ENTITLEMENT KEY from here"}),"\n",(0,p.jsx)(e.p,{children:(0,p.jsx)(e.a,{href:"https://myibm.ibm.com/products-services/containerlibrary",children:"IBM Container Library"})}),"\n",(0,p.jsx)(e.p,{children:"On a host with docker installed:"}),"\n",(0,p.jsx)(e.pre,{children:(0,p.jsx)(e.code,{children:"export ENTITLED_REGISTRY=cp.icr.io\nexport ENTITLED_REGISTRY_USER=cp\nexport ENTITLED_REGISTRY_KEY=[ENTITLEMENT KEY]\n"})}),"\n",(0,p.jsx)(e.p,{children:'Also export your private registry credentials. You will need to know the values for "LOCAL REGISTRY ADDRESS," "LOCAL REGISTRY USER," and "LOCAL REGISTRY KEY".'}),"\n",(0,p.jsx)(e.pre,{children:(0,p.jsx)(e.code,{children:"export LOCAL_REGISTRY=[LOCAL REGISTRY ADDRESS]\nexport LOCAL_REGISTRY_USER=[LOCAL REGISTRY USER]\nexport LOCAL_REGISTRY_KEY=[LOCAL REGISTRY KEY]\n"})}),"\n",(0,p.jsx)(e.p,{children:"Login to IBM Entitled Registry with Docker"}),"\n",(0,p.jsx)(e.pre,{children:(0,p.jsx)(e.code,{children:'docker login "$ENTITLED_REGISTRY" -u "$ENTITLED_REGISTRY_USER" -p "$ENTITLED_REGISTRY_KEY"\n'})}),"\n",(0,p.jsx)(e.p,{children:"The following image list comes from the IBM FileNet Content Manager Case File ver 1.6.2."}),"\n",(0,p.jsx)(e.p,{children:"On your local host with docker installed, run the following pull commands:"}),"\n",(0,p.jsx)(e.pre,{children:(0,p.jsx)(e.code,{children:"docker pull cp.icr.io/cp/cp4a/fncm/cpe:ga-5510-p8cpe-if001\ndocker pull cp.icr.io/cp/cp4a/fncm/cpe-sso,ga-5510-p8cpe-if001\ndocker pull cp.icr.io/cp/cp4a/fncm/css:ga-5510-p8css-if001\ndocker pull cp.icr.io/cp/cp4a/fncm/cmis:ga-307-cmis-la103\ndocker pull cp.icr.io/cp/cp4a/fncm/extshare:ga-3013-es-la102\ndocker pull cp.icr.io/cp/cp4a/fncm/graphql:ga-5510-p8cgql-if001\ndocker pull cp.icr.io/cp/cp4a/ban/navigator:ga-3013-icn-la102\ndocker pull cp.icr.io/cp/cp4a/ban/navigator-sso:ga-3013-icn-la102\ndocker pull cp.icr.io/cp/cp4a/fncm/taskmgr:ga-3013-tm-la102\ndocker pull icr.io/cpopen/ibm-fncm-operator-bundle:55.10.1\n"})}),"\n",(0,p.jsx)(e.p,{children:"If including the IER container, also pull that image:"}),"\n",(0,p.jsx)(e.admonition,{type:"note",children:(0,p.jsxs)(e.p,{children:["As of this writing the latest IER version is ",(0,p.jsx)(e.a,{href:"https://www.ibm.com/support/fixcentral/swg/doSelectFixes?options.selectedFixes=5.2.1.8-IER-IF005&continue=1&source=dbluesearch&mhsrc=ibmsearch_a&mhq=enterprise+records",children:"5.2.1.8-IER-IF005"})]})}),"\n",(0,p.jsx)(e.pre,{children:(0,p.jsx)(e.code,{children:"docker pull cp.icr.io/cp/cp4a/ier/ier:ga-5218-ier-if005\n"})}),"\n",(0,p.jsx)(e.p,{children:"Docker login to your private registry"}),"\n",(0,p.jsx)(e.pre,{children:(0,p.jsx)(e.code,{children:'docker login "$LOCAL_REGISTRY" -u "$LOCAL_REGISTRY_USER" -p "$LOCAL_REGISTRY_KEY"\n'})}),"\n",(0,p.jsx)(e.p,{children:"Let's tag the images we've pulled to be pushed to the private registry:"}),"\n",(0,p.jsx)(e.pre,{children:(0,p.jsx)(e.code,{children:"docker tag cp.icr.io/cp/cp4a/fncm/cpe:ga-5510-p8cpe-if001 $LOCAL_REGISTRY/cp/cp4a/fncm/cpe:ga-5510-p8cpe-if001\ndocker tag cp.icr.io/cp/cp4a/fncm/cpe:ga-5510-p8cpe-if001-amd64 $LOCAL_REGISTRY/cp/cp4a/fncm/cpe:ga-5510-p8cpe-if001-amd64\ndocker tag cp.icr.io/cp/cp4a/fncm/cpe-sso,ga-5510-p8cpe-if001 $LOCAL_REGISTRY/cp/cp4a/fncm/cpe-sso,ga-5510-p8cpe-if001 \ndocker tag cp.icr.io/cp/cp4a/fncm/cpe-sso:ga-5510-p8cpe-if001-amd64 $LOCAL_REGISTRY/cp/cp4a/fncm/cpe-sso:ga-5510-p8cpe-if001-amd64 \ndocker tag cp.icr.io/cp/cp4a/fncm/css:ga-5510-p8css-if001 $LOCAL_REGISTRY/cp/cp4a/fncm/css:ga-5510-p8css-if001\ndocker tag cp.icr.io/cp/cp4a/fncm/css:ga-5510-p8css-if001-amd64 $LOCAL_REGISTRY/cp/cp4a/fncm/css:ga-5510-p8css-if001-amd64 \ndocker tag cp.icr.io/cp/cp4a/fncm/cmis:ga-307-cmis-la103 $LOCAL_REGISTRY/cp/cp4a/fncm/cmis:ga-307-cmis-la103\ndocker tag cp.icr.io/cp/cp4a/fncm/cmis:ga-307-cmis-la103-amd64 $LOCAL_REGISTRY/cp/cp4a/fncm/cmis:ga-307-cmis-la103-amd64\ndocker tag cp.icr.io/cp/cp4a/fncm/extshare:ga-3013-es-la102 $LOCAL_REGISTRY/cp/cp4a/fncm/extshare:ga-3013-es-la102\ndocker tag cp.icr.io/cp/cp4a/fncm/extshare:ga-3013-es-la102-amd64 $LOCAL_REGISTRY/cp/cp4a/fncm/extshare:ga-3013-es-la102-amd64\ndocker tag cp.icr.io/cp/cp4a/fncm/graphql:ga-5510-p8cgql-if001 $LOCAL_REGISTRY/cp/cp4a/fncm/graphql:ga-5510-p8cgql-if001\ndocker tag cp.icr.io/cp/cp4a/fncm/graphql:ga-5510-p8cgql-if001-amd64 $LOCAL_REGISTRY/cp/cp4a/fncm/graphql:ga-5510-p8cgql-if001-amd64\ndocker tag cp.icr.io/cp/cp4a/ban/navigator:ga-3013-icn-la102 $LOCAL_REGISTRY/cp/cp4a/ban/navigator:ga-3013-icn-la102\ndocker tag cp.icr.io/cp/cp4a/ban/navigator:ga-3013-icn-la102-amd64 $LOCAL_REGISTRY/cp/cp4a/ban/navigator:ga-3013-icn-la102-amd64\ndocker tag cp.icr.io/cp/cp4a/ban/navigator-sso:ga-3013-icn-la102 $LOCAL_REGISTRY/cp/cp4a/ban/navigator-sso:ga-3013-icn-la102\ndocker tag cp.icr.io/cp/cp4a/ban/navigator-sso:ga-3013-icn-la102-amd64 $LOCAL_REGISTRY/cp/cp4a/ban/navigator-sso:ga-3013-icn-la102-amd64\ndocker tag cp.icr.io/cp/cp4a/fncm/taskmgr:ga-3013-tm-la102 $LOCAL_REGISTRY/cp/cp4a/fncm/taskmgr:ga-3013-tm-la102\ndocker tag cp.icr.io/cp/cp4a/fncm/taskmgr:ga-3013-tm-la102-amd64 $LOCAL_REGISTRY/cp/cp4a/fncm/taskmgr:ga-3013-tm-la102-amd64\ndocker tag icr.io/cpopen/icp4a-content-operator:22.0.2-IF003 $LOCAL_REGISTRY/cpopen/icp4a-content-operator:22.0.2-IF003\ndocker tag icr.io/cpopen/icp4a-content-operator:22.0.2-IF003-amd64 $LOCAL_REGISTRY/cpopen/icp4a-content-operator:22.0.2-IF003-amd64 \ndocker tag icr.io/cpopen/ibm-fncm-operator-bundle:55.10.1 $LOCAL_REGISTRY/cpopen/ibm-fncm-operator-bundle:55.10.1\n"})}),"\n",(0,p.jsx)(e.p,{children:"If including IER"}),"\n",(0,p.jsx)(e.pre,{children:(0,p.jsx)(e.code,{children:"docker tag cp.icr.io/cp/cp4a/ier/ier:ga-5218-ier-if005 $LOCAL_REGISTRY/cp/cp4a/ier/ier:ga-5218-ier-if005\n"})}),"\n",(0,p.jsx)(e.p,{children:"Now let's push the images to the local or private registry"}),"\n",(0,p.jsx)(e.pre,{children:(0,p.jsx)(e.code,{children:"docker push $LOCAL_REGISTRY/cp/cp4a/fncm/cpe:ga-5510-p8cpe-if001\ndocker push $LOCAL_REGISTRY/cp/cp4a/fncm/cpe:ga-5510-p8cpe-if001-amd64\ndocker push $LOCAL_REGISTRY/cp/cp4a/fncm/cpe-sso,ga-5510-p8cpe-if001 \ndocker push $LOCAL_REGISTRY/cp/cp4a/fncm/cpe-sso:ga-5510-p8cpe-if001-amd64 \ndocker push $LOCAL_REGISTRY/cp/cp4a/fncm/css:ga-5510-p8css-if001\ndocker push $LOCAL_REGISTRY/cp/cp4a/fncm/css:ga-5510-p8css-if001-amd64 \ndocker push $LOCAL_REGISTRY/cp/cp4a/fncm/cmis:ga-307-cmis-la103\ndocker push $LOCAL_REGISTRY/cp/cp4a/fncm/cmis:ga-307-cmis-la103-amd64\ndocker push $LOCAL_REGISTRY/cp/cp4a/fncm/extshare:ga-3013-es-la102\ndocker push $LOCAL_REGISTRY/cp/cp4a/fncm/extshare:ga-3013-es-la102-amd64\ndocker push $LOCAL_REGISTRY/cp/cp4a/fncm/graphql:ga-5510-p8cgql-if001\ndocker push $LOCAL_REGISTRY/cp/cp4a/fncm/graphql:ga-5510-p8cgql-if001-amd64\ndocker push $LOCAL_REGISTRY/cp/cp4a/ban/navigator:ga-3013-icn-la102\ndocker push $LOCAL_REGISTRY/cp/cp4a/ban/navigator:ga-3013-icn-la102-amd64\ndocker push $LOCAL_REGISTRY/cp/cp4a/ban/navigator-sso:ga-3013-icn-la102\ndocker push $LOCAL_REGISTRY/cp/cp4a/ban/navigator-sso:ga-3013-icn-la102-amd64\ndocker push $LOCAL_REGISTRY/cp/cp4a/fncm/taskmgr:ga-3013-tm-la102\ndocker push $LOCAL_REGISTRY/cp/cp4a/fncm/taskmgr:ga-3013-tm-la102-amd64\ndocker push $LOCAL_REGISTRY/cpopen/icp4a-content-operator:22.0.2-IF003\ndocker push $LOCAL_REGISTRY/cpopen/icp4a-content-operator:22.0.2-IF003-amd64 \ndocker push $LOCAL_REGISTRY/cpopen/ibm-fncm-operator-bundle:55.10.1\n"})}),"\n",(0,p.jsx)(e.p,{children:"If including IER"}),"\n",(0,p.jsx)(e.pre,{children:(0,p.jsx)(e.code,{children:"docker push $LOCAL_REGISTRY/cp/cp4a/icp4a-operator:21.0.3-IF023\ndocker push $LOCAL_REGISTRY/cp/cp4a/ier/ier:ga-5218-ier-if005\n"})})]})}function d(c={}){const{wrapper:e}={...(0,n.a)(),...c.components};return e?(0,p.jsx)(e,{...c,children:(0,p.jsx)(l,{...c})}):l(c)}},1151:(c,e,a)=>{a.d(e,{Z:()=>o,a:()=>i});var p=a(7294);const n={},r=p.createContext(n);function i(c){const e=p.useContext(r);return p.useMemo((function(){return"function"==typeof c?c(e):{...e,...c}}),[e,c])}function o(c){let e;return e=c.disableParentContext?"function"==typeof c.components?c.components(n):c.components||n:i(c.components),p.createElement(r.Provider,{value:e},c.children)}}}]);