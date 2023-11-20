"use strict";(self.webpackChunkwebsite=self.webpackChunkwebsite||[]).push([[4960],{8363:(e,n,i)=>{i.r(n),i.d(n,{assets:()=>a,contentTitle:()=>s,default:()=>p,frontMatter:()=>o,metadata:()=>l,toc:()=>d});var r=i(5893),t=i(1151);const o={id:"solution-deploy-ier",sidebar_position:4,title:"IBM Enterprise Records"},s=void 0,l={id:"Create/Deploy/solution-deploy-ier",title:"IBM Enterprise Records",description:"Deploy IER",source:"@site/docs/3-Create/Deploy/ier.mdx",sourceDirName:"3-Create/Deploy",slug:"/Create/Deploy/solution-deploy-ier",permalink:"/Create/Deploy/solution-deploy-ier",draft:!1,unlisted:!1,editUrl:"https://github.com/ibm-client-engineering/solution-filenet-aws/tree/main/packages/create-docusaurus/templates/shared/docs/3-Create/Deploy/ier.mdx",tags:[],version:"current",sidebarPosition:4,frontMatter:{id:"solution-deploy-ier",sidebar_position:4,title:"IBM Enterprise Records"},sidebar:"tutorialSidebar",previous:{title:"FNCM Operator",permalink:"/Create/Deploy/solution-deploy-operator"},next:{title:"Use Cases",permalink:"/category/use-cases"}},a={},d=[{value:"Deploy IER",id:"deploy-ier",level:2},{value:"Create the <code>ibm-ier-secret</code>",id:"create-the-ibm-ier-secret",level:3},{value:"Updating CR for IER deployment",id:"updating-cr-for-ier-deployment",level:3},{value:"Apply the CR",id:"apply-the-cr",level:3},{value:"Appendix",id:"appendix",level:2},{value:"Applying fix for IER",id:"applying-fix-for-ier",level:3}];function c(e){const n={a:"a",admonition:"admonition",code:"code",h2:"h2",h3:"h3",li:"li",p:"p",pre:"pre",ul:"ul",...(0,t.a)(),...e.components};return(0,r.jsxs)(r.Fragment,{children:[(0,r.jsx)(n.h2,{id:"deploy-ier",children:"Deploy IER"}),"\n",(0,r.jsx)(n.p,{children:"If IBM Enterprise Records is required, you should have already staged the image per the previous instructions in Staging."}),"\n",(0,r.jsxs)(n.h3,{id:"create-the-ibm-ier-secret",children:["Create the ",(0,r.jsx)(n.code,{children:"ibm-ier-secret"})]}),"\n",(0,r.jsx)(n.p,{children:"If deploying IER, create the following"}),"\n",(0,r.jsx)(n.pre,{children:(0,r.jsx)(n.code,{className:"language-tsx",children:'kubectl create secret generic ibm-ier-secret \\\n--from-literal=appLoginUsername="cpadmin" \\\n--from-literal=appLoginPassword="Password" \\\n--from-literal=keystorePassword="p@ssw0rd" \\\n--from-literal=ltpaPassword="p@ssw0rd"\n'})}),"\n",(0,r.jsx)(n.h3,{id:"updating-cr-for-ier-deployment",children:"Updating CR for IER deployment"}),"\n",(0,r.jsx)(n.p,{children:"In the filenet CR you used to deploy the cluster, make the following changes and additions:"}),"\n",(0,r.jsx)(n.pre,{children:(0,r.jsx)(n.code,{className:"language-yaml",children:"  content_optional_components:\n    cpe: true\n    graphql: true\n    cmis: false\n    css: false\n    es: false\n    tm: false\n    ban: true\n    // highlight-start\n    ier: true\n    // highlight-end\n\n"})}),"\n",(0,r.jsxs)(n.p,{children:["After the ",(0,r.jsx)(n.code,{children:"navigator_configuration"})," entry in the CR, add the following section"]}),"\n",(0,r.jsx)(n.pre,{children:(0,r.jsx)(n.code,{className:"language-yaml",children:'  ier_configuration:\n    arch:\n      amd64: "3 - Most preferred"\n    replica_count: 2\n    ier_ext_tls_secret_name:\n    ier_auth_ca_secret_name:\n    image:\n      // highlight-start\n      # This should point to whatever repo you staged the image in. Leave this as default if using IBM\'s registry\n      repository: cp.icr.io/cp/cp4a/ier/ier\n      // highlight-end\n      tag: ga-5218-ier-if005\n      pull_policy: IfNotPresent\n      // highlight-start\n      # This NEEDS to be set to the correct secret name. Make sure it\'s the one you created above.\n    ier_secret_name: ibm-ier-secret\n      // highlight-end\n    log:\n      format: json\n    resources:\n      requests:\n        cpu: 500m\n        memory: 512Mi\n      limits:\n        cpu: 1\n        memory: 1024Mi\n    auto_scaling:\n      enabled: false\n      max_replicas: 3\n      min_replicas: 1\n      target_cpu_utilization_percentage: 80\n    ier_production_setting:\n      license: accept\n    collectd_enable_plugin_write_graphite: false\n    run_as_user: \n    datavolume:\n      existing_pvc_for_ier_instance: ""\n    probe:\n      readiness:\n        initial_delay_seconds: 120\n        period_seconds: 5\n        timeout_seconds: 10\n        failure_threshold: 6\n      liveness:\n        initial_delay_seconds: 600\n        period_seconds: 5\n        timeout_seconds: 5\n        failure_threshold: 6\n'})}),"\n",(0,r.jsx)(n.h3,{id:"apply-the-cr",children:"Apply the CR"}),"\n",(0,r.jsx)(n.pre,{children:(0,r.jsx)(n.code,{className:"language-bash",children:"kubectl apply -f ibm_fncm_cr_production.yaml\n"})}),"\n",(0,r.jsx)(n.p,{children:"Wait for about five minutes or so and then check to see if the pod has spun up."}),"\n",(0,r.jsx)(n.pre,{children:(0,r.jsx)(n.code,{className:"language-tsx",children:"kubectl get pods\nNAME                                          READY   STATUS    RESTARTS   AGE\nfncmdeploy-cmis-deploy-654774fd5f-5xtnr       1/1     Running   0          6d6h\nfncmdeploy-cpe-deploy-7d7dbffc94-n86tt        1/1     Running   0          3d9h\nfncmdeploy-css-deploy-1-66bbd484b-qzrl9       1/1     Running   0          6d7h\nfncmdeploy-es-deploy-58f9659b8b-klmjh         1/1     Running   0          6d6h\nfncmdeploy-graphql-deploy-775766b99d-cx899    1/1     Running   0          6d6h\n// highlight-start\nfncmdeploy-ier-deploy-6f7465cd5d-sxp9d        1/1     Running   0          7h55m\n// highlight-end\nfncmdeploy-navigator-deploy-58b9c95c4-k9gx7   1/1     Running   0          157m\nfncmdeploy-tm-deploy-7d4fd64759-x28qw         1/1     Running   0          6d6h\nibm-fncm-operator-748884b478-qkd4f            1/1     Running   0          4d2h\npostgres-759fd876ff-d5fxd                     1/1     Running   0          6d9h\n\n"})}),"\n",(0,r.jsx)(n.h2,{id:"appendix",children:"Appendix"}),"\n",(0,r.jsx)(n.h3,{id:"applying-fix-for-ier",children:"Applying fix for IER"}),"\n",(0,r.jsxs)(n.admonition,{type:"info",children:[(0,r.jsx)(n.p,{children:"As of 23.0.x release of CP4BA, the following bug was introduced into IBM FileNet Content Manager:"}),(0,r.jsx)(n.p,{children:'When trying to access the IBM Enterprise Records desktop, an error message says that you cannot connect to the web client.\nThe log also shows that an exception was thrown "java.lang.NoClassDefFoundError: org.apache.xerces.xni.parser.XMLEntityResolver".'}),(0,r.jsx)(n.p,{children:"Cause:\nAfter moving to Java 11, IERApplicationPlugin.jar is unable to resolve the path to XercesImpl.jar in the ICN container."}),(0,r.jsxs)(n.p,{children:["Tracked in this ",(0,r.jsx)(n.a,{href:"https://www.ibm.com/support/pages/ibm-cloud-pak-business-automation-230x-known-limitations#I42202",children:"link"})]}),(0,r.jsx)(n.p,{children:"The following instructions handle addressing this missing jar file."})]}),"\n",(0,r.jsx)(n.p,{children:"We have included the required files here."}),"\n",(0,r.jsxs)(n.ul,{children:["\n",(0,r.jsx)(n.li,{children:(0,r.jsx)(n.a,{href:"https://github.com/ibm-client-engineering/solution-filenet-aws/blob/main/static/deployment_files/ExtraJars/ier-library.xml",children:"ier-library.xml"})}),"\n",(0,r.jsx)(n.li,{children:(0,r.jsx)(n.a,{href:"https://github.com/ibm-client-engineering/solution-filenet-aws/blob/main/static/deployment_files/ExtraJars/xercesImpl-2.12.2.jar",children:"xercesImpl-2.12.2.jar"})}),"\n"]}),"\n",(0,r.jsx)(n.p,{children:"Keep in mind that future releases of CP4BA and FileNet may not require this fix to be applied. This is currently only applicable to 23.0.1."}),"\n",(0,r.jsx)(n.p,{children:"Determine the navigator pod with the following command:"}),"\n",(0,r.jsx)(n.pre,{children:(0,r.jsx)(n.code,{className:"language-tsx",children:"kubectl get pods\nNAME                                          READY   STATUS    RESTARTS   AGE\nfncmdeploy-cmis-deploy-654774fd5f-5xtnr       1/1     Running   0          12d\nfncmdeploy-cpe-deploy-7d7dbffc94-n86tt        1/1     Running   0          9d\nfncmdeploy-css-deploy-1-66bbd484b-qzrl9       1/1     Running   0          12d\nfncmdeploy-es-deploy-58f9659b8b-klmjh         1/1     Running   0          12d\nfncmdeploy-graphql-deploy-775766b99d-cx899    1/1     Running   0          12d\nfncmdeploy-ier-deploy-6f7465cd5d-sxp9d        1/1     Running   0          6d8h\n// highlight-next-line\nfncmdeploy-navigator-deploy-58b9c95c4-kt6jc   1/1     Running   0          3d9h\nfncmdeploy-tm-deploy-7d4fd64759-x28qw         1/1     Running   0          12d\nibm-fncm-operator-748884b478-qkd4f            1/1     Running   0          10d\npostgres-759fd876ff-d5fxd                     1/1     Running   0          12d\n"})}),"\n",(0,r.jsxs)(n.p,{children:["Create the ",(0,r.jsx)(n.code,{children:"ier-jars"})," subdirectory on the navigator pod:"]}),"\n",(0,r.jsx)(n.pre,{children:(0,r.jsx)(n.code,{className:"language-tsx",children:"kubectl exec -it fncmdeploy-navigator-deploy-58b9c95c4-kt6jc -- mkdir configDropins/overrides/ier-jars\n"})}),"\n",(0,r.jsxs)(n.p,{children:["Upload the ",(0,r.jsx)(n.code,{children:"ier-library.xml"})," and the ",(0,r.jsx)(n.code,{children:"xercesImpl-2.12.2.jar"})," to that subdirectory on the navigator pod."]}),"\n",(0,r.jsx)(n.pre,{children:(0,r.jsx)(n.code,{className:"language-tsx",children:"kubectl cp ier-library.xml fncmdeploy-navigator-deploy-58b9c95c4-kt6jc:configDropins/overrides/\nkubectl cp xercesImpl-2.12.2.jar fncmdeploy-navigator-deploy-58b9c95c4-kt6jc:configDropins/overrides/ier-jars/xercesImpl.jar\n"})}),"\n",(0,r.jsx)(n.p,{children:"Scale the navigator deployment down and up. If your replicas are more that 1, scale appropriately."}),"\n",(0,r.jsx)(n.pre,{children:(0,r.jsx)(n.code,{className:"language-tsx",children:"kubectl scale deploy fncmdeploy-navigator-deploy --replicas=0\nkubectl scale deploy fncmdeploy-navigator-deploy --replicas=1\n"})})]})}function p(e={}){const{wrapper:n}={...(0,t.a)(),...e.components};return n?(0,r.jsx)(n,{...e,children:(0,r.jsx)(c,{...e})}):c(e)}},1151:(e,n,i)=>{i.d(n,{Z:()=>l,a:()=>s});var r=i(7294);const t={},o=r.createContext(t);function s(e){const n=r.useContext(o);return r.useMemo((function(){return"function"==typeof e?e(n):{...n,...e}}),[n,e])}function l(e){let n;return n=e.disableParentContext?"function"==typeof e.components?e.components(t):e.components||t:s(e.components),r.createElement(o.Provider,{value:n},e.children)}}}]);